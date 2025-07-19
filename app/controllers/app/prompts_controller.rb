class App::PromptsController < App::ApplicationController
  before_action :set_prompt, only: [:show, :edit, :update]
  layout -> { request.headers["Turbo-Frame"] ? false : "app_application" }

  def index
    @prompts = Current.user.prompts
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
    @prompt = Prompt.new(target: 'wordpress')
    
    respond_to do |format|
      format.html { render layout: !turbo_frame_request? }
    end
  end

  def create
    @prompt = Current.user.prompts.build(prompt_params)
    
    Rails.logger.debug "Creating prompt with params: #{prompt_params.inspect}"
    Rails.logger.debug "Request format: #{request.format}"
    Rails.logger.debug "Turbo frame request?: #{turbo_frame_request?}"
    
    respond_to do |format|
    if @prompt.save
        Rails.logger.debug "Prompt saved successfully"
        format.html { 
          if turbo_frame_request?
            # Check if we're coming from the WordPress content page or the new page
            if params[:context] == 'inline' || request.referer&.include?('wordpress_contents')
              # This is inline creation from WordPress content page
              render turbo_stream: [
                turbo_stream.update("prompt_form", ""),
                turbo_stream.replace("prompt_selection", partial: "app/wordpress_contents/prompt_selection", locals: { wordpress_prompts: Current.user.prompts.where(target: 'wordpress'), form: nil })
              ]
            else
              # This is from the dedicated new page, redirect back to prompts index
              redirect_to app_prompts_path, notice: "Prompt created successfully"
            end
          else
      redirect_to app_prompts_path, notice: "Prompt created successfully"
          end
        }
        format.json { render json: { success: true, prompt: @prompt } }
    else
        Rails.logger.debug "Failed to save prompt: #{@prompt.errors.full_messages}"
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @prompt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
    if @prompt.update(prompt_params)
        format.html { 
          if turbo_frame_request?
            # Check if we're coming from the WordPress content page or the edit page
            if params[:context] == 'inline' || request.referer&.include?('wordpress_contents')
              # This is inline editing from WordPress content page
              render turbo_stream: [
                turbo_stream.update("prompt_form", ""),
                turbo_stream.replace("prompt_selection", partial: "app/wordpress_contents/prompt_selection", locals: { wordpress_prompts: Current.user.prompts.where(target: 'wordpress'), form: nil })
              ]
            else
              # This is from the dedicated edit page, redirect back to prompts index
              redirect_to app_prompts_path, notice: "Prompt updated successfully"
            end
          else
      redirect_to app_prompts_path, notice: "Prompt updated successfully"
          end
        }
        format.json { render json: { success: true, prompt: @prompt } }
    else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @prompt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_prompt
    @prompt = Current.user.prompts.find(params[:id])
  end

  def prompt_params
    params.require(:prompt).permit(:target, :user_prompt, :system_prompt)
  end
end