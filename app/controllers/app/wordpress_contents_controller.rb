class App::WordpressContentsController < App::ApplicationController
  before_action :set_wordpress_content, only: [:show, :edit, :update, :destroy, :publish, :publish_modal, :regenerate]

  def index
    @wordpress_contents = Current.user.wordpress_contents.includes(:prompt)
  end

  def show
  end

  def new
    @wordpress_content = WordpressContent.new
    @model_groups = OpenrouterService.fetch_models
  end

  def create
    @wordpress_content = Current.user.wordpress_contents.build(wordpress_content_params)
    
    if @wordpress_content.save
      @wordpress_content.generate_content!
      redirect_to edit_app_wordpress_content_path(@wordpress_content), notice: "WordPress content created successfully"
    else
      @model_groups = OpenrouterService.fetch_models
      render :new
    end
  end

  def edit
    @model_groups = OpenrouterService.fetch_models
  end

  def update
    respond_to do |format|
      if @wordpress_content.update(wordpress_content_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("action-buttons", "<div id='update-notification' style='background: #10B981; color: white; padding: 12px 16px; border-radius: 8px; margin-left: 12px; display: inline-flex; align-items: center; font-weight: 500; box-shadow: 0 4px 12px rgba(0,0,0,0.15);'>✅ Updated successfully!</div><script>setTimeout(() => { const el = document.getElementById('update-notification'); if (el) el.remove(); }, 3000);</script>")
          ]
        end
        format.html { redirect_to edit_app_wordpress_content_path(@wordpress_content), notice: "WordPress content updated successfully" }
      else
        @model_groups = OpenrouterService.fetch_models
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def regenerate
    # Handle regenerate_only parameter for the content editor button
    if params[:regenerate_only] == "true"
      respond_to do |format|
        format.turbo_stream do
          # Show loading animation first
          render turbo_stream: turbo_stream.replace("wordpress_content_editor", partial: "generating_content")
        end
        format.html { redirect_to edit_app_wordpress_content_path(@wordpress_content) }
      end
      
      # Start the regeneration in the background
      @wordpress_content.generate_content!
      return
    end
    
    # Update the wordpress content with any new params
    if params[:wordpress_content].present?
      if @wordpress_content.update(wordpress_content_params)
        # Regenerate the content with updated settings
        @wordpress_content.generate_content!
        redirect_to edit_app_wordpress_content_path(@wordpress_content), notice: "Content is being regenerated with updated settings. This may take a few moments."
      else
        @model_groups = OpenrouterService.fetch_models
        render :edit, status: :unprocessable_entity
      end
    else
      # Just regenerate with existing settings
      @wordpress_content.generate_content!
      redirect_to edit_app_wordpress_content_path(@wordpress_content), notice: "Content is being regenerated. This may take a few moments."
    end
  end

  def destroy
    @wordpress_content.destroy!
    redirect_to app_wordpress_contents_path, notice: "WordPress content deleted successfully"
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to app_wordpress_contents_path, alert: "Failed to delete WordPress content"
  end

  def publish_modal
    @wordpress_websites = Current.user.wordpress_websites
    
    respond_to do |format|
      format.turbo_stream do 
        render turbo_stream: turbo_stream.append("body", partial: "publish_modal") 
      end
    end
  end

  def close_modal
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace("modal_container", "") 
      }
      format.html { 
        redirect_back(fallback_location: app_wordpress_contents_path)
      }
    end
  end

  def publish
    wordpress_website_id = params[:wordpress_website_id]
    
    if wordpress_website_id.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "Please select a WordPress website to publish to" })
        end
        format.html { redirect_to app_wordpress_content_path(@wordpress_content), alert: "Please select a WordPress website to publish to" }
      end
      return
    end
    
    wordpress_website = Current.user.wordpress_websites.find(wordpress_website_id)
    
    # Launch background job to publish to WordPress
    WordpressPublishJob.perform_later(@wordpress_content.id, wordpress_website.id)
    
    success_message = "Content is being published to #{wordpress_website.url}. This may take a few moments."
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("modal"),
          turbo_stream.append("body", partial: "shared/notification", locals: { 
            type: "success", 
            message: success_message,
            duration: 6000
          })
        ]
      end
      format.html { redirect_to app_wordpress_contents_path, notice: success_message }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("modal_container", partial: "publish_modal_error", locals: { error: "WordPress website not found" })
      end
      format.html { redirect_to app_wordpress_contents_path, alert: "WordPress website not found" }
    end
  end

  private

  def set_wordpress_content
    @wordpress_content = Current.user.wordpress_contents.find(params[:id])
  end

  def wordpress_content_params
    params.require(:wordpress_content).permit(:title, :content, :status, :keyword, :cta_url, :prompt_id, :ai_model)
  end
end