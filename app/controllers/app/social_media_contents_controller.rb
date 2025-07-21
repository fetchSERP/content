class App::SocialMediaContentsController < App::ApplicationController
  before_action :set_social_media_content, only: [:show, :edit, :update, :destroy, :publish_modal, :publish]

  def index
    @social_media_contents = Current.user.social_media_contents
  end

  def new
    @social_media_content = SocialMediaContent.new(platform: params[:platform] || 'linkedin')
    @social_media_prompts = Current.user.prompts.where(target: params[:platform] || 'linkedin')
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
      redirect_to app_social_media_contents_path, notice: "Social media content created successfully"
    else
      @social_media_prompts = Current.user.prompts.where(target: params[:platform] || 'linkedin')
      @model_groups = OpenrouterService.fetch_models
      render :new
    end
  end

  def edit
    @social_media_content = SocialMediaContent.find(params[:id])
    @social_media_prompts = Current.user.prompts.where(target: params[:platform] || 'linkedin')
    @model_groups = OpenrouterService.fetch_models
  end

  def update
    @social_media_content = SocialMediaContent.find(params[:id])
    if @social_media_content.update(social_media_content_params)
      redirect_to app_social_media_contents_path, notice: "Social media content updated successfully"
    else
      @social_media_prompts = Current.user.prompts.where(target: params[:platform] || 'linkedin')
      @model_groups = OpenrouterService.fetch_models
      render :edit
    end
  end

  def destroy
    @social_media_content = SocialMediaContent.find(params[:id])
    @social_media_content.destroy
    redirect_to app_social_media_contents_path, notice: "Social media content deleted successfully"
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
        format.html { redirect_to app_social_media_content_path(@social_media_content), alert: "Please select a #{@social_media_content.platform} account" }
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
      format.html { redirect_to app_social_media_contents_path, notice: success_message }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "#{@social_media_content.platform} account not found" }) }
      format.html { redirect_to app_social_media_contents_path, alert: "#{@social_media_content.platform} account not found" }
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