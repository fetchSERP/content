class Social::Linkedin::PostService < BaseService
  def initialize(authentication_provider)
    @authentication_provider = authentication_provider
  end

  def call(payload)
    person_urn = "urn:li:person:#{@authentication_provider.uid}" 

    uri = URI.parse("https://api.linkedin.com/v2/ugcPosts")

    post_body = {
      author: person_urn,
      lifecycleState: "PUBLISHED",
      specificContent: {
        "com.linkedin.ugc.ShareContent": {
          shareCommentary: {
            text: payload
          },
          shareMediaCategory: "NONE"
        }
      },
      visibility: {
        "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
      }
    }

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@authentication_provider.token}"
    request["Content-Type"] = "application/json"
    request["X-Restli-Protocol-Version"] = "2.0.0"
    request.body = post_body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end
end
