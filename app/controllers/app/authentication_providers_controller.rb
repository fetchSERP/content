class App::AuthenticationProvidersController < App::ApplicationController
  def create
    auth_hash = request.env["omniauth.auth"]
    username = case auth_hash.provider
    when 'twitter2'
      auth_hash.dig(:extra, :raw_info, :data, :username)
    when 'linkedin'
      auth_hash.dig(:extra, :raw_info, :name)
    else
      "Unknown"
    end
    
    Current.user.authentication_providers.create!(
      provider: auth_hash.provider,
      uid: auth_hash.uid,
      token: auth_hash.credentials.token,
      refresh_token: auth_hash.credentials.refresh_token,
      expires_at: Time.at(auth_hash.credentials.expires_at).to_datetime,
      username: username
    )
    redirect_to app_root_path, notice: "Authentication provider created"
  end

  def destroy
    provider = Current.user.authentication_providers.find(params[:id])
    provider_name = provider.provider.capitalize
    provider.destroy
    redirect_to app_root_path, notice: "#{provider_name} connection removed successfully"
  end
end