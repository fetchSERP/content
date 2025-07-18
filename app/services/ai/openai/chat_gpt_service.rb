class Ai::Openai::ChatGptService < BaseService
  def initialize(model: "gpt-4.1-nano")
    @model = model
  end

  def call(user_prompt:, system_prompt:, response_schema:)
    client = OpenAI::Client.new(api_key: Rails.application.credentials.openrouter_api_key, base_url: "https://openrouter.ai/api/v1")
    raw_resp = client.chat.completions.create(
      model: @model,
      response_format: {
        type: "json_schema",
        json_schema: response_schema
      },
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt }
      ]
      # temperature: 0.2
    )

    # The official OpenAI SDK returns a ChatCompletion object. Convert it to a plain Ruby hash so we can
    # safely dig into it regardless of the SDK version.
    resp = raw_resp.respond_to?(:deep_to_h) ? raw_resp.deep_to_h : raw_resp.to_h

    content = resp.dig(:choices, 0, :message, :content) || resp.dig("choices", 0, "message", "content")

    return nil if content.blank?

    # Extract the JSON block (the assistant may wrap it in markdown/code fences).
    json_str = content[/\{.*\}/m]
    JSON.parse(json_str) if json_str.present?
  end
end
