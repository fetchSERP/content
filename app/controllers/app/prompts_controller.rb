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
    target = params[:target] || 'wordpress'
    
    # Platform-specific default prompts
    default_prompts = {
      'linkedin' => {
        user_prompt: "Generate a LinkedIn post (max 1300 characters) about {{keyword}} and include the CTA URL {{cta_url}}. Use emojis and professional tone.",
        system_prompt: "You are a marketing assistant specializing in creating professional LinkedIn posts with emojis, hashtags, and engaging professional content."
      },
      'x' => {
        user_prompt: "Generate an X (Twitter) post (max 280 characters) about {{keyword}} and include the CTA URL {{cta_url}}. Use hashtags and engaging tone.",
        system_prompt: "You are a marketing assistant specializing in creating viral X (Twitter) posts with emojis, hashtags, and concise, engaging content."
      },
      'wordpress' => {
        user_prompt: "Generate a WordPress blog post about {{keyword}} and include the following CTA URL link tag : <a href='{{cta_url}}'>{{cta_url}}</a>. Include SEO-optimized content.",
        system_prompt: "You are a marketing assistant specializing in creating SEO-optimized WordPress blog posts with engaging content."
      }
    }
    
    defaults = default_prompts[target] || default_prompts['wordpress']
    
    @prompt = Prompt.new(
      target: target,
      user_prompt: defaults[:user_prompt],
      system_prompt: defaults[:system_prompt]
    )
  end

  def create
    @prompt = Current.user.prompts.build(prompt_params)
    
    respond_to do |format|
      if @prompt.save
        # Determine form name from referer
        form_name = if request.referer&.include?('recurring_social_media_contents')
                      'recurring_social_media_content'
                    elsif request.referer&.include?('wordpress_contents')
                      'wordpress_content'
                    else
                      'social_media_content'
                    end
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("prompt_form", ""),
            turbo_stream.replace("prompt_selection_area", 
              partial: "shared/prompt_selection_content", 
              locals: { 
                prompts: Current.user.prompts.enabled.where(target: @prompt.target),
                platform: @prompt.target,
                form_name: form_name, 
                selected_prompt_id: @prompt.id
              }
            )
          ]
        end
        format.html do
          # If coming from a content creation page, use turbo stream response to stay on page
          if request.referer&.include?('wordpress_contents') || 
             request.referer&.include?('social_media_contents') || 
             request.referer&.include?('recurring_social_media_contents')
            render turbo_stream: [
              turbo_stream.update("prompt_form", ""),
              turbo_stream.replace("prompt_selection_area", 
                partial: "shared/prompt_selection_content", 
                locals: { 
                  prompts: Current.user.prompts.enabled.where(target: @prompt.target),
                  platform: @prompt.target,
                  form_name: form_name, 
                  selected_prompt_id: @prompt.id
                }
              )
            ]
          else
            redirect_to app_prompts_path, notice: "Prompt created successfully"
          end
        end
        format.json { render json: { success: true, prompt: @prompt } }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("prompt_form", 
            partial: "form"
          ), status: :unprocessable_entity
        end
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
        
        # Determine form name from referer
        form_name = if request.referer&.include?('recurring_social_media_contents')
                      'recurring_social_media_content'
                    elsif request.referer&.include?('wordpress_contents')
                      'wordpress_content'
                    else
                      'social_media_content'
                    end

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("prompt_form", ""),
            turbo_stream.replace("prompt_selection_area", 
              partial: "shared/prompt_selection_content", 
              locals: { 
                prompts: Current.user.reload.prompts.enabled.where(target: platform),
                platform: platform,
                form_name: form_name, 
                selected_prompt_id: @prompt.id
              }
            )
          ]
        end

        format.html { redirect_to app_prompts_path, notice: "Prompt updated successfully" }
        format.json { render json: { success: true, prompt: @prompt } }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("prompt_form", 
            partial: "form"
          ), status: :unprocessable_entity
        end
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