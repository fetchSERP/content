class Social::X::PostService < BaseService
  def initialize(authentication_provider)
    @x_credentials = {
      bearer_token: authentication_provider.token
    }
    @x_client = X::Client.new(**@x_credentials)
  end
  attr_reader :x_client

  def call(payload)
    @x_client.post("tweets", %Q({"text": "#{payload}"}))
  end
end
