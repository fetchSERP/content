class App::BulkWordpressContentGenerationsController < App::ApplicationController
  def new
    @domains = Current.user.domains.includes(:keywords)
    @wordpress_prompts = Current.user.prompts.enabled.where(target: 'wordpress')
    @available_models = OpenrouterService.fetch_models
    @model_groups = @available_models
  end

  def refresh_keywords
    @domains = Current.user.domains.includes(:keywords)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("bulk_keywords_list", partial: "keywords_list", locals: { domains: @domains })
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

    keywords = Keyword.joins(:domain).where(id: keyword_ids, domains: { user: Current.user })
    prompt   = Current.user.prompts.find_by(id: prompt_id)

    created = 0
    keywords.each do |keyword|
      wc = Current.user.wordpress_contents.create!(
        title: keyword.name.titleize,
        keyword: keyword.name,
        status: 'draft',
        prompt: prompt,
        ai_model: ai_model,
        cta_url: cta_url,
        publish_on_create: true
      )

      # Enqueue generation job (implement job separately)
      GenerateWordpressContentJob.perform_later(wc, wordpress_website_id)
      created += 1
    end

    redirect_to app_wordpress_contents_path, notice: "#{created} WordPress content items queued for generation."
  end
end 