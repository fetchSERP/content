class App::BulkWordpressContentGenerationsController < App::ApplicationController
  def new
    @domains = Current.user.domains.includes(keywords: :children)
    @wordpress_prompts = Current.user.prompts.enabled.where(target: 'wordpress')
    @available_models = OpenrouterService.fetch_models
    @model_groups = @available_models
  end

  def generate_long_tail_keywords
    keyword_id = params[:keyword_id]
    
    begin
      keyword = Keyword.joins(:domain).find_by(id: keyword_id, domains: { user: Current.user })
      
      unless keyword
        render turbo_stream: turbo_stream.replace("long_tail_#{keyword_id}", partial: "long_tail_keywords", locals: {
          error: "Keyword not found or access denied",
          pillar_keyword: nil,
          long_tail_keywords: []
        })
        return
      end

      # Clear existing long tail keywords first
      keyword.children.where(is_long_tail: true).destroy_all
      
      # Enqueue background job to generate new keywords
      GenerateLongTailKeywordsJob.perform_later(keyword, Current.user)

      # Show a simple generation started message
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("long_tail_#{keyword.id}", partial: "long_tail_keywords", locals: {
            loading: true,
            pillar_keyword: keyword,
            long_tail_keywords: []
          })
        end
      end

    rescue => e
      Rails.logger.error "Long tail keyword generation failed: #{e.message}"
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("long_tail_#{keyword&.id || keyword_id}", partial: "long_tail_keywords", locals: {
            error: "Failed to generate long tail keywords: #{e.message}",
            pillar_keyword: keyword,
            long_tail_keywords: [],
            loading: false
          })
        end
      end
    end
  end

  def create
    keyword_ids = params[:keyword_ids] || []
    prompt_id   = params[:prompt_id]
    ai_model    = params[:ai_model]
    cta_url     = params[:cta_url]
    wordpress_website_id = params[:wordpress_website_id]
    
    # Validate required inputs
    if keyword_ids.empty? || prompt_id.blank? || ai_model.blank? || cta_url.blank? || wordpress_website_id.blank?
      flash.now[:alert] = "Please select at least one keyword, a prompt, an AI model, a CTA URL, and a WordPress website."
      # reload variables for form
      @domains = Current.user.domains.includes(:keywords)
      @wordpress_prompts = Current.user.prompts.enabled.where(target: 'wordpress')
      @model_groups   = OpenrouterService.fetch_models

      # Preserve user selections
      @selected_keyword_ids        = keyword_ids.map(&:to_i)
      @selected_prompt_id          = prompt_id
      @selected_ai_model           = ai_model
      @selected_cta_url            = cta_url
      @selected_wordpress_website_id = wordpress_website_id
      render :new, status: :unprocessable_entity and return
    end

    # Separate regular keywords from long tail keywords
    regular_keyword_ids = keyword_ids.select { |id| id.is_a?(String) && id.match?(/^\d+$/) }.map(&:to_i)
    long_tail_keyword_ids = keyword_ids.select { |id| id.is_a?(String) && id.start_with?('longtail_') }

    # Fetch regular keywords from database
    regular_keywords = Keyword.joins(:domain).where(id: regular_keyword_ids, domains: { user: Current.user })
    
    # Fetch long tail keywords from database using the submitted data
    long_tail_keywords = []
    long_tail_keyword_ids.each do |lt_id|
      # Extract the actual keyword ID from the long tail format
      if lt_id.match(/^longtail_(\d+)_(\d+)$/)
        pillar_keyword_id = $1.to_i
        index = $2.to_i
        
        # Find the pillar keyword and its long tail children
        pillar_keyword = Keyword.joins(:domain).find_by(id: pillar_keyword_id, domains: { user: Current.user })
        if pillar_keyword
          # Get the long tail keyword at the specified index
          long_tail_keyword = pillar_keyword.children.where(is_long_tail: true).offset(index).first
          long_tail_keywords << long_tail_keyword if long_tail_keyword
        end
      end
    end

    # Enqueue bulk generation job with delays to prevent API rate limiting
    BulkGenerateWordpressContentJob.perform_later(
      keyword_ids,
      prompt_id,
      ai_model,
      cta_url,
      wordpress_website_id,
      Current.user.id
    )

    # Calculate total keywords for the notice
    total_keywords = regular_keyword_ids.size + long_tail_keyword_ids.size
    long_tail_count = long_tail_keyword_ids.size
    
    redirect_to app_wordpress_contents_path, notice: "#{total_keywords} WordPress content items queued for generation (including #{long_tail_count} long tail keywords). Generation will proceed with delays to prevent API rate limiting."
  end
end 