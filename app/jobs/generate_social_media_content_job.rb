class GenerateSocialMediaContentJob < ApplicationJob
  queue_as :default

  def perform(social_media_content, auto_publish: false)
    prompt = social_media_content.prompt
    user_prompt = prompt.user_prompt.gsub("{{keyword}}", social_media_content.keyword).gsub("{{cta_url}}", social_media_content.cta_url)
    system_prompt = prompt.system_prompt
    fetchserp_client = FetchSERP::Client.new(api_key: social_media_content.user.fetchserp_api_key)
    response = fetchserp_client.generate_social_content(
      user_prompt: user_prompt,
      system_prompt: system_prompt,
      ai_model: social_media_content.ai_model
    )
    content = response.data.dig("response")
    social_media_content.update!(content: content["content"])
    
    if auto_publish && social_media_content.recurring_social_media_content.present?
      authentication_provider_id = social_media_content.user.authentication_providers.where(provider: social_media_content.platform == "x" ? "twitter2" : social_media_content.platform).first.id
      SocialMediaPublishJob.perform_later(social_media_content.id, authentication_provider_id)
    end
    
    # Broadcast to main social media content list
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{social_media_content.user_id}",
      target: "social_media_content_#{social_media_content.id}",
      partial: "app/social_media_contents/social_media_content",
      locals: { social_media_content: social_media_content }
    )
    
    # Also broadcast to content editor on edit page (if user is on edit page)
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{social_media_content.user_id}",
      target: "content_editor",
      partial: "app/social_media_contents/content_editor",
      locals: { social_media_content: social_media_content, form: nil }
    )
    
    # Show success notification
    Turbo::StreamsChannel.broadcast_append_to(
      "streaming_channel_#{social_media_content.user_id}",
      target: "body",
      html: "<div id='generation-notification' style='position: fixed; top: 20px; right: 20px; background: #10B981; color: white; padding: 16px 20px; border-radius: 8px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); z-index: 99999; font-weight: 500;'>✨ Content generated successfully!</div><script>setTimeout(() => { const el = document.getElementById('generation-notification'); if (el) el.remove(); }, 4000);</script>"
    )
    
    broadcast_credit(social_media_content.user)
  end

  def response_schema
    {
      "strict": true,
      "name": "Social_Media_Content_Generator",
      "description": "Generate a social media post optimized for search engines targeting a specific keyword",
      "schema": {
        "type": "object",
        "properties": {
          "content": {
            "type": "string",
            "description": "The main content of the post, between 800-1500 words. The targeting keyword must appear in the first 100 words."
          }
        },
        "additionalProperties": false,
        "required": [ "content" ]
      }
    }
  end
end
