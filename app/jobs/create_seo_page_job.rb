class CreateSeoPageJob < ApplicationJob
  queue_as :default

  def perform(keyword)
    return if Page.exists?(keyword: keyword)
    seo_page = Ai::Openai::ChatGptService.new.call(
      user_prompt: user_prompt(keyword),
      system_prompt: system_prompt,
      response_schema: response_schema
    )
    Page.create!(
      keyword: keyword,
      slug: keyword.name.parameterize,
      meta_title: seo_page["meta_title"],
      meta_description: seo_page["meta_description"],
      headline: seo_page["headline"],
      subheading: seo_page["subheading"],
      content: seo_page["content"]
    )
  end

  # User prompt describing the task for ChatGPT to generate an SEO page
  def user_prompt(keyword)
    link_instruction =
      if keyword.keyword.present?
        "- The html must include a html link to https://content.fetchser.com/#{keyword.keyword.name.parameterize}"
      else
        "- The html must include a html anchor link to https://www.fetchserp.com"
      end
    <<~PROMPT
      Create a well-optimized SEO page targeting the keyword "#{keyword.name}" with a #{keyword.search_intent} search intent.
      The page should be designed for an audience aligned with a #{keyword.search_intent} intent.
      The following requirements must be met:
      - The meta title should be concise, under 60 characters, and include the keyword.
      - The meta description should be clear, under 160 characters, and include the keyword.
      - The H1 page title should be informative and contain the keyword.
      - The page content should be between 800-1500 words, engaging, and informative.
      - The keyword must appear within the first 100 words of the content.
      - Use the keyword naturally and avoid keyword stuffing.
      - The content should have a natural flow and be SEO-friendly.
      - The content must be html code wrapped in <section> tags.
      - The html content must be valid and formatted correctly.
      - The content must be optimized for search engines.
      - The html must use best practices for SEO and accessibility.
      - The html must use best UI and UX practices.
      - The html must be styled with Tailwind CSS.
      - The html must be responsive and mobile-friendly.
      - The html must not contain h1 tags and the content title should be different from the headline or subheading.
      - Space out the content with paragraphs and use a friendly, professional tone suitable for an audience interested in learning about "#{keyword.name}".
      - Use a friendly, professional tone suitable for an audience interested in learning about "#{keyword.name}".
      - Use text-gray-300 text color on bg-[#0F172A] background for text and background
      - Use text-gray-100 for titles and subtitles
      - use font-sans font family
      - Tailor all content to satisfy the #{keyword.search_intent} search intent.
      #{link_instruction}
    PROMPT
  end

  # System prompt to guide ChatGPT in generating SEO-friendly content
  def system_prompt
    <<~PROMPT
      You are an expert in SEO and content writing. Your task is to generate SEO-optimized content for a given keyword. 
      The content should meet the specified requirements, including appropriate keyword placement, SEO-friendly structure, and compelling writing.
      Ensure that all elements such as meta tags, titles, and content are optimized for search engines while remaining user-friendly.
    PROMPT
  end

  def response_schema
    {
      "strict": true,
      "name": "SEO_Page_Generator",
      "description": "Generate an SEO page optimized for search engines targeting a specific keyword",
      "schema": {
        "type": "object",
        "properties": {
          "meta_title": {
            "type": "string",
            "description": "The meta title tag, under 60 characters, including the keyword"
          },
          "meta_description": {
            "type": "string",
            "description": "The meta description tag, under 160 characters, including the keyword"
          },
          "headline": {
            "type": "string",
            "description": "The H1 page title, relevant to the keyword"
          },
          "subheading": {
            "type": "string",
            "description": "The subheading of the page, relevant to the keyword"
          },
          "content": {
            "type": "string",
            "description": "The main content of the page, between 800-1500 words. The targeting keyword must appear in the first 100 words."
          }
        },
        "additionalProperties": false,
        "required": ["meta_title", "meta_description", "headline", "subheading", "content"]
      }
    }
  end
end
 