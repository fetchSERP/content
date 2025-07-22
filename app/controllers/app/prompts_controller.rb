class App::PromptsController < App::ApplicationController
  before_action :set_prompt, only: [:show, :edit, :update, :disable]
  layout -> { turbo_frame_request? ? false : "app_application" }

  def index
    @prompts = Current.user.prompts.enabled
  end

  def show
    respond_to do |format|
      format.json { render json: @prompt }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: 'Prompt not found' }, status: :not_found }
    end
  end

  def new
    @prompt = Prompt.new(
      target: params[:target] || 'wordpress',
      user_prompt: "Generate a {{platform}} post about {{keyword}} and include the cta url {{cta_url}}",
      system_prompt: "You are a marketing assistant specializing in creating professional social media posts with emojis."
    )
  end

  def create
    @prompt = Current.user.prompts.build(prompt_params)
    
    respond_to do |format|
      if @prompt.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("prompt_form", ""),
            turbo_stream.replace("prompt_selection", 
              partial: "app/social_media_contents/prompt_selection", 
              locals: { 
                prompts: Current.user.prompts.enabled.where(target: @prompt.target),
                form: nil
              }
            )
          ]
        end
        format.html { redirect_to app_prompts_path, notice: "Prompt created successfully" }
        format.json { render json: { success: true, prompt: @prompt } }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @prompt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    # No respond_to needed - just render the view
  end

  def update
    respond_to do |format|
      if @prompt.update(prompt_params)
        @prompt.reload # Ensure data is fresh from DB
        
        # Get the current platform from the referer URL
        platform = request.referer&.match(/platform=([^&]+)/)&.captures&.first || @prompt.target
        prompts = Current.user.prompts.reload.where(target: platform)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("prompt_form", ""),
            turbo_stream.replace("prompt_selection", 
              partial: "app/social_media_contents/prompt_selection", 
              locals: { 
                prompts: Current.user.reload.prompts.enabled.where(target: platform),
                form: nil
              }
            )
          ]
        end

        format.html { redirect_to app_prompts_path, notice: "Prompt updated successfully" }
        format.json { render json: { success: true, prompt: @prompt } }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @prompt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def disable
    @prompt.update!(disabled: true)
    redirect_back(fallback_location: app_prompts_path, notice: "Prompt disabled successfully")
  end

  private

  def set_prompt
    @prompt = Current.user.prompts.unscoped.find(params[:id])
  end

  def prompt_params
    params.require(:prompt).permit(:target, :user_prompt, :system_prompt)
  end
end