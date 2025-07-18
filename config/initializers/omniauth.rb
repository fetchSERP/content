Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  provider :linkedin, Rails.application.credentials.linkedin_client_id, Rails.application.credentials.linkedin_client_secret, scope: "openid profile email w_member_social"
  provider :twitter2, Rails.application.credentials.twitter_client_id, Rails.application.credentials.twitter_client_secret, callback_path: "/auth/twitter2/callback", scope: "tweet.write tweet.read users.read offline.access"
end