class App::SocialMediaContentsController < App::ApplicationController
  before_action :set_social_media_content, only: [:show, :edit, :update, :destroy, :publish_modal, :publish, :regenerate, :update_prompts]

  def index
    @social_media_contents = Current.user.social_media_contents
  end

  def new
    @social_media_content = SocialMediaContent.new(platform: params[:platform] || 'linkedin')
    @social_media_prompts = Current.user.prompts.enabled.where(target: @social_media_content.platform)
    @model_groups = OpenrouterService.fetch_models
  end

  def show
    @social_media_content = SocialMediaContent.find(params[:id])
  end

  def create
    @social_media_content = SocialMediaContent.new(social_media_content_params)
    @social_media_content.user = Current.user
    
    if @social_media_content.save
      @social_media_content.generate!
      redirect_to edit_app_social_media_content_path(@social_media_content), notice: "Social media content is being generated. This may take a few moments."
    else
      @social_media_prompts = Current.user.prompts.enabled.where(target: @social_media_content.platform)
      @model_groups = OpenrouterService.fetch_models
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @social_media_content = SocialMediaContent.find(params[:id])
    @social_media_prompts = Current.user.prompts.enabled.where(target: @social_media_content.platform)
    @model_groups = OpenrouterService.fetch_models
  end

  def update
    @social_media_content = SocialMediaContent.find(params[:id])
    
    respond_to do |format|
      if @social_media_content.update(social_media_content_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("action-buttons", "<div id='update-notification' style='background: #10B981; color: white; padding: 12px 16px; border-radius: 8px; margin-left: 12px; display: inline-flex; align-items: center; font-weight: 500; box-shadow: 0 4px 12px rgba(0,0,0,0.15);'>✅ Updated successfully!</div><script>setTimeout(() => { const el = document.getElementById('update-notification'); if (el) el.remove(); }, 3000);</script>")
          ]
        end
        format.html { redirect_to edit_app_social_media_content_path(@social_media_content), notice: "Social media content updated successfully" }
      else
        @social_media_prompts = Current.user.prompts.enabled.where(target: @social_media_content.platform).reload
        @model_groups = OpenrouterService.fetch_models
        
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @social_media_content = SocialMediaContent.find(params[:id])
    @social_media_content.destroy
    redirect_to app_social_media_contents_path, notice: "Social media content deleted successfully"
  end

  def regenerate
    # Handle regenerate_only parameter for the content editor button
    if params[:regenerate_only] == "true"
      respond_to do |format|
        format.turbo_stream do
          # Show loading animation first - render the HTML partial within a turbo_stream response
          render turbo_stream: turbo_stream.replace("content_editor", partial: "generating_content")
        end
        format.html { redirect_to edit_app_social_media_content_path(@social_media_content) }
      end
      
      # Start the regeneration in the background
      @social_media_content.generate!
      return
    end
    
    # Update the social media content with any new params
    if params[:social_media_content].present?
      if @social_media_content.update(social_media_content_params)
        # Regenerate the content with updated settings
        @social_media_content.generate!
        redirect_to edit_app_social_media_content_path(@social_media_content), notice: "Content is being regenerated with updated settings. This may take a few moments."
      else
        @social_media_prompts = Current.user.prompts.enabled.where(target: @social_media_content.platform).reload
        @model_groups = OpenrouterService.fetch_models
        render :edit, status: :unprocessable_entity
      end
    else
      # Just regenerate with existing settings
      @social_media_content.generate!
      redirect_to edit_app_social_media_content_path(@social_media_content), notice: "Content is being regenerated. This may take a few moments."
    end
  end

  def update_prompts_for_new
    platform = params[:platform]
    prompts = Current.user.prompts.enabled.where(target: platform)
    
    # Create a temporary object for the partial
    social_media_content = SocialMediaContent.new(platform: platform)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("prompt_selection_area", partial: "prompt_selection_area", locals: { prompts: prompts, social_media_content: social_media_content })
      end
    end
  end

  def update_prompts
    platform = params[:platform]
    prompts = Current.user.prompts.enabled.where(target: platform)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("prompt_selection_area", partial: "prompt_selection_area", locals: { prompts: prompts, social_media_content: @social_media_content })
      end
    end
  end

  # GET /publish_modal
  def publish_modal
    # list of linkedin authentication providers
    @authentication_providers = Current.user.authentication_providers.where(provider: @social_media_content.platform == "linkedin" ? "linkedin" : "twitter2")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("body", partial: "publish_modal", locals: { social_media_content: @social_media_content, authentication_providers: @authentication_providers })
      end
    end
  end

  # PATCH /publish
  def publish
    provider_id = params[:authentication_provider_id]
    if provider_id.blank?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "Please select a #{@social_media_content.platform} account" }) }
      end
      return
    end

    provider = Current.user.authentication_providers.find(provider_id)
    # Enqueue background job (ensure job defined)
    SocialMediaPublishJob.perform_later(@social_media_content.id, provider.id)

    success_message = "Post is being published to #{@social_media_content.platform}. This may take a few moments."

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("modal"),
          turbo_stream.append("body", partial: "shared/notification", locals: { type: "success", message: success_message, duration: 6000 })
        ]
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "#{@social_media_content.platform} account not found" }) }
    end
  end

  private

  def set_social_media_content
    @social_media_content = Current.user.social_media_contents.find(params[:id])
  end

  def social_media_content_params
    params.require(:social_media_content).permit(:content, :ai_model, :prompt_id, :cta_url, :keyword, :platform)
  end
end