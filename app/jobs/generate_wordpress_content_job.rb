class GenerateWordpressContentJob < ApplicationJob
  queue_as :default

  def perform(wordpress_content, wordpress_website_id = nil)
    prompt = wordpress_content.prompt
    user_prompt = prompt.user_prompt.gsub("{{keyword}}", wordpress_content.keyword).gsub("{{cta_url}}", wordpress_content.cta_url)
    system_prompt = prompt.system_prompt
    fetchserp_client = FetchSERP::Client.new(api_key: wordpress_content.user.fetchserp_api_key)
    response = fetchserp_client.generate_wordpress_content(
      user_prompt: user_prompt,
      system_prompt: system_prompt,
      ai_model: wordpress_content.ai_model
    )
    content = response.data.dig("response")
    wordpress_content.update!(title: content["title"], content: content["content"])
    if wordpress_content.publish_on_create
      WordpressPublishJob.perform_later(wordpress_content.id, wordpress_website_id)
    end
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{wordpress_content.user_id}",
      target: "wordpress_content_#{wordpress_content.id}",
      partial: "app/wordpress_contents/wordpress_content",
      locals: { wordpress_content: wordpress_content }
    )
    broadcast_credit(wordpress_content.user)
  end

  def response_schema
    {
      "strict": true,
      "name": "WordPress_Content_Generator",
      "description": "Generate an SEO page optimized for search engines targeting a specific keyword",
      "schema": {
        "type": "object",
        "properties": {
          "title": {
            "type": "string",
            "description": "The title of the page, relevant to the keyword"
          },
          "content": {
            "type": "string",
            "description": "The main content of the page, between 800-1500 words. The targeting keyword must appear in the first 100 words."
          }
        },
        "additionalProperties": false,
        "required": [ "title", "content" ]
      }
    }
  end
end
