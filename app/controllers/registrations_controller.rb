class RegistrationsController < ApplicationController
  
  allow_unauthenticated_access only: %i[new create]
  before_action :resume_session, only: %i[new create]
  after_action :create_fetchserp_user, only: %i[create]

  def new
    redirect_to app_root_path if Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if verify_recaptcha(model: @user) && @user.save
      create_fetchserp_user if Rails.env.production?
      CreateKeywordsWatchUserJob.perform_later(email_address: user_params[:email_address], password: user_params[:password], password_confirmation: user_params[:password_confirmation], fetchserp_api_key: @user.fetchserp_api_key) if Rails.env.production?
      start_new_session_for @user
      redirect_to app_root_path, notice: "You've successfully signed up. Welcome!"
    else
      unless verify_recaptcha(model: @user)
        @user.errors.add(:base, "Please complete the reCAPTCHA verification")
      end
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end

  def create_fetchserp_user
    uri = URI.parse("#{Rails.env.production? ? "https://www.fetchserp.com" : "http://localhost:3009"}/api/internal/users")
    request = Net::HTTP::Post.new(uri)
    request.add_field("Authorization", "Bearer #{Rails.application.credentials.fetchserp_app_api_key}")
    request.set_form_data("email_address" => user_params[:email_address], "password" => user_params[:password], "password_confirmation" => user_params[:password_confirmation])
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
    if response.code == "201"
       @user.update(fetchserp_api_key: JSON.parse(response.body).dig("data", "user", "api_token"))
    else
      Rails.logger.error("Failed to create fetchserp user: #{response.body}")
    end
  end
end


