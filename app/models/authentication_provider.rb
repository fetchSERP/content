class AuthenticationProvider < ApplicationRecord
  belongs_to :user

  def refresh_x_token!
    uri = URI.parse("https://api.twitter.com/2/oauth2/token")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    auth_string = Base64.strict_encode64("#{Rails.application.credentials.twitter_client_id}:#{Rails.application.credentials.twitter_client_secret}")
    request["Authorization"] = "Basic #{auth_string}"
    
    request.body = URI.encode_www_form(
      grant_type:    "refresh_token",
      refresh_token: refresh_token,
      client_id:    Rails.application.credentials.twitter_client_id
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      update!(
        token:         data["access_token"],
        refresh_token: data["refresh_token"],
        expires_at:    Time.current + data["expires_in"].to_i.seconds
      )
      true
    else
      Rails.logger.error "Twitter token refresh failed for user #{user_id}: #{response.code} - #{response.body}"
      error_data = JSON.parse(response.body)
      Rails.logger.error "Error details: #{error_data}"
      false
    end
  rescue => e
    Rails.logger.error "Exception during Twitter token refresh: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end
end
