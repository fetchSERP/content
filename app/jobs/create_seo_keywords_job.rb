class CreateSeoKeywordsJob < ApplicationJob
  queue_as :default

  def perform(keyword)
    keywords = Ai::Openai::ChatGptService.new.call(
      user_prompt: user_prompt(keyword),
      system_prompt: system_prompt,
      response_schema: response_schema
    )
    keywords["keywords"].each do |item|
      name = item["keyword"]
      intent = item["search_intent"].to_s.downcase

      kw = Keyword.find_or_initialize_by(name: name)
      kw.is_long_tail = true
      kw.keyword = keyword
      kw.search_intent = intent
      kw.save!
    end
  end

  def response_schema
    {
      strict: true,
      name: "SEO_keywords_generator",
      description: "Generate 20 long tail keywords for the given keyword.",
      schema: {
        type: "object",
        properties: {
          keywords: {
            type: "array",
            description: "An array of 20 objects, each containing a long tail keyword and its search intent.",
            items: {
              type: "object",
              properties: {
                keyword: {
                  type: "string",
                  description: "The long tail keyword."
                },
                search_intent: {
                  type: "string",
                  description: "Search intent category.",
                  enum: ["informational", "navigational", "commercial", "transactional"]
                }
              },
              required: ["keyword", "search_intent"],
              additionalProperties: false
            }
          }
        },
        required: ["keywords"],
        additionalProperties: false
      }
    }
  end
  

  def user_prompt(keyword)
    <<~PROMPT
      Generate 20 long tail keywords for the given keyword: #{keyword.name}. For each keyword, also provide its search intent as one of the following categories: informational, navigational, commercial, or transactional.
    PROMPT
  end

  def system_prompt
    <<~PROMPT
      You are an expert in SEO and content writing. Your task is to generate SEO-optimized content for a given keyword. 
    PROMPT
  end

end