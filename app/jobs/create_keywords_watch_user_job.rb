class CreateKeywordsWatchUserJob < ApplicationJob
  queue_as :default

  def perform(email_address:, password:, password_confirmation:, fetchserp_api_key:)
    uri = URI.parse("#{Rails.env.production? ? "https://tracker.fetchserp.com" : "http://localhost:3012"}/api/internal/users")
    request = Net::HTTP::Post.new(uri)
    request.add_field("Authorization", "Bearer #{Rails.application.credentials.keywords_watch_app_api_key}")
    request.set_form_data("email_address" => email_address, "password" => password, "password_confirmation" => password_confirmation, "fetchserp_api_key" => fetchserp_api_key)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
  end
end