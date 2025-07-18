class Wordpress::PostService
  def initialize(wordpress_website)
    @wordpress_website = wordpress_website
  end

  # payload: { title:, content:, status: 'publish', ... }
  def call(payload)
    url = URI("#{@wordpress_website.url}/wp-json/wp/v2/posts")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Basic " + Base64.strict_encode64("#{@wordpress_website.username}:#{@wordpress_website.password}")
    request.body = payload.to_json

    response = http.request(request)

    if response.code.to_i.between?(200,299)
      JSON.parse(response.body)
    else
      raise "WordPress Error: #{response.code} #{response.body}"
    end
  end
end
