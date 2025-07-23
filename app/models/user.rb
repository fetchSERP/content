class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authentication_providers, dependent: :destroy
  has_many :wordpress_websites, dependent: :destroy
  has_many :wordpress_contents, dependent: :destroy
  has_many :prompts, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :social_media_contents, dependent: :destroy
  has_many :recurring_social_media_contents, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Returns an initialized FetchSERP::Client using the user's personal API key
  def fetchserp_client
    @fetchserp_client ||= FetchSERP::Client.new(api_key: fetchserp_api_key)
  end

  # Fetch remaining credits from FetchSERP API (real-time)
  def fetchserp_credits
    resp = fetchserp_client.user
    resp.data.dig("user", "api_credit")
  rescue => _e
    nil
  end
end
