class GenerateLinkedinContentJob < ApplicationJob
  queue_as :default

  def perform(linkedin_content)
    prompt = linkedin_content.prompt
    user_prompt = prompt.user_prompt.gsub("{{keyword}}", linkedin_content.keyword).gsub("{{cta_url}}", linkedin_content.cta_url)
    system_prompt = prompt.system_prompt
    content = Ai::Openai::ChatGptService.new(model: linkedin_content.ai_model).call(user_prompt: user_prompt, system_prompt: system_prompt, response_schema: response_schema)
    linkedin_content.update!(content: content["content"])
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{linkedin_content.user_id}",
      target: "linkedin_content_#{linkedin_content.id}",
      partial: "app/linkedin_contents/linkedin_content",
      locals: { linkedin_content: linkedin_content }
    )
  end

  def response_schema
    {
      "strict": true,
      "name": "LinkedIn_Content_Generator",
      "description": "Generate a LinkedIn post optimized for search engines targeting a specific keyword",
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
