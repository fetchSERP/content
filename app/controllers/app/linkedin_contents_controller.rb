class App::LinkedinContentsController < App::ApplicationController
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

  private

  def linkedin_content_params
    params.require(:linkedin_content).permit(:content, :ai_model, :prompt_id, :cta_url, :keyword)
  end
end