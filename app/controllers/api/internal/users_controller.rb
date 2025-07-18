class Api::Internal::UsersController < ApplicationController
  # Allow unauthenticated requests to create a user via this internal API endpoint
  allow_unauthenticated_access only: %i[create update_fetchserp_api_key update_password]
  protect_from_forgery with: :null_session
  before_action :authenticate_content_app!
  # POST /api/internal/users
  # Expected params (JSON or form-data):
  #   email_address            - String, required, unique
  #   password                 - String, required
  #   password_confirmation    - String, required (must match password)
  #
  # Successful response (201):
  #   {
  #     "data": {
  #       "user": {
  #         "id": 1,
  #         "email_address": "user@example.com",
  #         "api_token": "<generated-token>"
  #       }
  #     }
  #   }
  #
  # Error response (422):
  #   {
  #     "errors": ["Email address has already been taken", "Password confirmation doesn't match Password"]
  #   }
  def create
    user = User.new(user_params)

    if user.save
      render json: {
        data: {
          user: {
            id: user.id,
            email_address: user.email_address,
          }
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_fetchserp_api_key
    user = User.find_by(email_address: params[:email_address])
    if user.nil?
      render json: { errors: ["User not found"] }, status: :not_found
      return
    end

    if user.update(fetchserp_api_key: params[:fetchserp_api_key])
      render json: { data: { user_id: user.id } }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_password
    user = User.find_by(email_address: params[:email_address])
    if user.nil?
      render json: { errors: ["User not found"] }, status: :not_found
      return
    end

    user.password = params[:password]
    user.password_confirmation = params[:password_confirmation]

    if user.save
      render json: { data: { user_id: user.id } }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # Accept raw parameters rather than requiring a nested :user key for simplicity of internal usage
    params.permit(:email_address, :password, :password_confirmation, :fetchserp_api_key)
  end

  def authenticate_content_app!
    unless request.headers["Authorization"] == "Bearer #{Rails.application.credentials.content_app_api_key}"
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
