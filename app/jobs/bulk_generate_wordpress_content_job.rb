class BulkGenerateWordpressContentJob < ApplicationJob
  queue_as :default

  def perform(keyword_ids, prompt_id, ai_model, cta_url, wordpress_website_id, user_id)
    user = User.find(user_id)
    
    # Separate regular keywords from long tail keywords
    regular_keyword_ids = keyword_ids.select { |id| id.is_a?(String) && id.match?(/^\d+$/) }.map(&:to_i)
    long_tail_keyword_ids = keyword_ids.select { |id| id.is_a?(String) && id.start_with?('longtail_') }

    # Fetch regular keywords from database
    regular_keywords = Keyword.joins(:domain).where(id: regular_keyword_ids, domains: { user: user })
    
    # Fetch long tail keywords from database
    long_tail_keywords = []
    long_tail_keyword_ids.each do |lt_id|
      # Extract the actual keyword ID from the long tail format
      if lt_id.match(/^longtail_(\d+)_(\d+)$/)
        pillar_keyword_id = $1.to_i
        index = $2.to_i
        
        # Find the pillar keyword and its long tail children
        pillar_keyword = Keyword.joins(:domain).find_by(id: pillar_keyword_id, domains: { user: user })
        if pillar_keyword
          # Get the long tail keyword at the specified index
          long_tail_keyword = pillar_keyword.children.where(is_long_tail: true).offset(index).first
          long_tail_keywords << long_tail_keyword if long_tail_keyword
        end
      end
    end

    # Combine all selected keywords
    all_keywords = regular_keywords + long_tail_keywords.compact
    prompt = user.prompts.find_by(id: prompt_id)

    created = 0
    all_keywords.each do |keyword|
      # Use the actual keyword name for title and content
      keyword_name = keyword.name
      
      wc = user.wordpress_contents.create!(
        title: keyword_name.titleize,
        keyword: keyword_name,
        status: 'draft',
        prompt: prompt,
        ai_model: ai_model,
        cta_url: cta_url,
        publish_on_create: true
      )

      # Enqueue generation job
      GenerateWordpressContentJob.perform_later(wc, wordpress_website_id)
      created += 1
      
      # Sleep 20 seconds between each to prevent API rate limiting
      sleep(20) unless keyword == all_keywords.last
    end

    Rails.logger.info "Bulk generation completed: #{created} WordPress content items queued for generation (including #{long_tail_keywords.size} long tail keywords)."
  end
end