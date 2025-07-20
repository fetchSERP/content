class App::LinkedinContentsController < App::ApplicationController
  before_action :set_linkedin_content, only: [:show, :edit, :update, :destroy, :publish_modal, :publish]

  def index
    @linkedin_contents = Current.user.linkedin_contents
  end

  def new
    @linkedin_content = LinkedinContent.new
    @linkedin_prompts = Current.user.prompts.where(target: 'linkedin')
    @model_groups = OpenrouterService.fetch_models
  end

  def show
    @linkedin_content = LinkedinContent.find(params[:id])
  end

  def create
    @linkedin_content = LinkedinContent.new(linkedin_content_params)
    @linkedin_content.user = Current.user
    if @linkedin_content.save
      @linkedin_content.generate!
      redirect_to app_linkedin_contents_path, notice: "LinkedIn content created successfully"
    else
      @linkedin_prompts = Current.user.prompts.where(target: 'linkedin')
      @model_groups = OpenrouterService.fetch_models
      render :new
    end
  end

  def edit
    @linkedin_content = LinkedinContent.find(params[:id])
    @linkedin_prompts = Current.user.prompts.where(target: 'linkedin')
    @model_groups = OpenrouterService.fetch_models
  end

  def update
    @linkedin_content = LinkedinContent.find(params[:id])
    if @linkedin_content.update(linkedin_content_params)
      redirect_to app_linkedin_contents_path, notice: "LinkedIn content updated successfully"
    else
      @linkedin_prompts = Current.user.prompts.where(target: 'linkedin')
      @model_groups = OpenrouterService.fetch_models
      render :edit
    end
  end

  def destroy
    @linkedin_content = LinkedinContent.find(params[:id])
    @linkedin_content.destroy
    redirect_to app_linkedin_contents_path, notice: "LinkedIn content deleted successfully"
  end

  # GET /publish_modal
  def publish_modal
    # list of linkedin authentication providers
    @authentication_providers = Current.user.authentication_providers.where(provider: 'linkedin')

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("body", partial: "publish_modal", locals: { linkedin_content: @linkedin_content, authentication_providers: @authentication_providers })
      end
    end
  end

  # PATCH /publish
  def publish
    provider_id = params[:authentication_provider_id]
    if provider_id.blank?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "Please select a LinkedIn account" }) }
        format.html { redirect_to app_linkedin_content_path(@linkedin_content), alert: "Please select a LinkedIn account" }
      end
      return
    end

    provider = Current.user.authentication_providers.find(provider_id)
    # Enqueue background job (ensure job defined)
    LinkedinPublishJob.perform_later(@linkedin_content.id, provider.id)

    success_message = "Post is being published to LinkedIn. This may take a few moments."

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("modal"),
          turbo_stream.append("body", partial: "shared/notification", locals: { type: "success", message: success_message, duration: 6000 })
        ]
      end
      format.html { redirect_to app_linkedin_contents_path, notice: success_message }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "LinkedIn account not found" }) }
      format.html { redirect_to app_linkedin_contents_path, alert: "LinkedIn account not found" }
    end
  end

  private

  def set_linkedin_content
    @linkedin_content = Current.user.linkedin_contents.find(params[:id])
  end

  def linkedin_content_params
    params.require(:linkedin_content).permit(:content, :ai_model, :prompt_id, :cta_url, :keyword)
  end
end