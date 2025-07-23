class App::RecurringSocialMediaContentsController < App::ApplicationController
  before_action :set_recurring_content, only: [:show, :edit, :update, :destroy, :toggle]

  def index
    @recurring_contents = Current.user.recurring_social_media_contents.includes(:prompt, :social_media_contents).order(created_at: :desc)
  end

  def new
    @recurring_content = RecurringSocialMediaContent.new(platform: 'linkedin')
    
    # Reuse exact same logic as bulk WordPress
    @domains = Current.user.domains.includes(keywords: :children)
    @available_models = OpenrouterService.fetch_models
    @model_groups = @available_models
  end

  def create
    keyword_names = extract_keyword_names_from_params
    
    @recurring_content = Current.user.recurring_social_media_contents.build(recurring_content_params)
    @recurring_content.keywords = keyword_names
    
    if @recurring_content.save
      # Start the job chain if active
      if @recurring_content.is_active?
        GenerateRecurringContentJob.perform_later(@recurring_content.id)
      end
      
      redirect_to app_recurring_social_media_contents_path, 
                  notice: "Recurring campaign created successfully! #{@recurring_content.is_active? ? 'Content generation started.' : 'Campaign is paused.'}"
    else
      # Reload form data on validation errors
      @domains = Current.user.domains.includes(keywords: :children)
      @available_models = OpenrouterService.fetch_models
      @model_groups = @available_models
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @generated_contents = @recurring_content.social_media_contents.includes(:prompt).order(created_at: :desc).limit(20)
  end

  def edit
    # Reuse same logic as new
    @domains = Current.user.domains.includes(keywords: :children)
    @available_models = OpenrouterService.fetch_models
    @model_groups = @available_models
    
    # Convert keywords back to selected state for form
    selected_keywords = @recurring_content.selected_keywords
    @selected_keyword_ids = selected_keywords.pluck(:id)
  end

  def update
    keyword_names = extract_keyword_names_from_params
    
    old_active_state = @recurring_content.is_active?
    
    if @recurring_content.update(recurring_content_params.merge(keywords: keyword_names))
      # Handle job chain based on active state changes
      handle_job_chain_on_update(old_active_state)
      
      redirect_to @recurring_content, notice: "Campaign updated successfully!"
    else
      @domains = Current.user.domains.includes(keywords: :children)
      @available_models = OpenrouterService.fetch_models
      @model_groups = @available_models
      @selected_keywords = @recurring_content.selected_keywords
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recurring_content.destroy!
    redirect_to app_recurring_social_media_contents_path, 
                notice: "Campaign deleted successfully. Associated generated content remains."
  end

  def toggle
    if @recurring_content.is_active?
      # Pause: set inactive (job chain will stop naturally)
      @recurring_content.update!(is_active: false)
      flash[:notice] = "Campaign paused. No new content will be generated."
    else
      # Resume: set active + restart job chain
      @recurring_content.update!(is_active: true)
      GenerateRecurringContentJob.perform_later(@recurring_content.id)
      flash[:notice] = "Campaign resumed. Content generation restarted."
    end
    
    redirect_back(fallback_location: app_recurring_social_media_contents_path)
  end

  def update_prompts_for_new
    platform = params[:platform]
    prompts = Current.user.prompts.enabled.where(target: platform)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("prompt_selection_area", 
          partial: "shared/prompt_selection_area_wrapper", 
          locals: { 
            prompts: prompts, 
            platform: platform, 
            form_name: "recurring_social_media_content", 
            selected_prompt_id: nil 
          })
      end
    end
  end

  def update_prompts
    platform = params[:platform]
    prompts = Current.user.prompts.enabled.where(target: platform)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("prompt_selection_area", 
          partial: "shared/prompt_selection_area_wrapper", 
          locals: { 
            prompts: prompts, 
            platform: platform, 
            form_name: "recurring_social_media_content", 
            selected_prompt_id: @recurring_content.prompt_id 
          })
      end
    end
  end

  private

  def set_recurring_content
    @recurring_content = Current.user.recurring_social_media_contents.find(params[:id])
  end

  def recurring_content_params
    params.require(:recurring_social_media_content).permit(
      :platform, :frequency, :prompt_id, :ai_model, :cta_url, :is_active
    )
  end

  def extract_keyword_names_from_params
    keyword_ids = params[:keyword_ids] || []
    
    # Separate regular keywords from long tail keywords (reuse exact logic from bulk WordPress)
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

    # Combine all selected keywords and return their names
    all_keywords = regular_keywords + long_tail_keywords.compact
    all_keywords.map(&:name)
  end

  def handle_job_chain_on_update(old_active_state)
    new_active_state = @recurring_content.is_active?
    
    if !old_active_state && new_active_state
      # Was inactive, now active - start job chain
      GenerateRecurringContentJob.perform_later(@recurring_content.id)
    end
    # If was active and still active, current job chain continues with new settings
    # If was active and now inactive, job chain will stop naturally
  end
end