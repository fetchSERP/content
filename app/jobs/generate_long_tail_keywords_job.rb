class GenerateLongTailKeywordsJob < ApplicationJob
  queue_as :default

  def perform(keyword, user)
    begin
      # Initialize FetchSERP client
      client = FetchSERP::Client.new(api_key: user.fetchserp_api_key)
      
      # Generate long tail keywords
      long_tail_response = client.long_tail_keywords_generator(keyword: keyword.name, count: 50)
      
      saved_long_tail_keywords = []
      # Save keywords to database
      long_tail_response.body.dig("data", "long_tail_keywords").each do |lt_keyword|
        lt_keyword_record = Keyword.create!(
          name: lt_keyword.strip,
          is_long_tail: true,
          keyword: keyword,  # Associate with pillar keyword
          domain: keyword.domain,  # Same domain as pillar keyword
          search_intent: 'informational'  # Default intent
        )
        saved_long_tail_keywords << lt_keyword_record
      end

      # Broadcast the updated content to replace the loading state
      Turbo::StreamsChannel.broadcast_replace_to(
        "streaming_channel_#{user.id}",
        target: "long_tail_#{keyword.id}",
        partial: "app/bulk_wordpress_content_generations/long_tail_keywords",
        locals: {
          pillar_keyword: keyword,
          long_tail_keywords: saved_long_tail_keywords,
          loading: false,
          error: nil
        }
      )

      # Update user credit
      broadcast_credit(user)

    rescue => e
      Rails.logger.error "Long tail keyword generation job failed: #{e.message}"
      
      # Broadcast error state
      Turbo::StreamsChannel.broadcast_replace_to(
        "streaming_channel_#{user.id}",
        target: "long_tail_#{keyword.id}",
        partial: "app/bulk_wordpress_content_generations/long_tail_keywords",
        locals: {
          pillar_keyword: keyword,
          long_tail_keywords: [],
          loading: false,
          error: "Failed to generate long tail keywords: #{e.message}"
        }
      )
    end
  end
end 