class App::DomainsController < App::ApplicationController
  def index
    @domains = Current.user.domains
  end

  def new
    @domain = Domain.new
  end

  def create
    @domain = Current.user.domains.build(domain_params)
    
    if @domain.save
      respond_to do |format|
        format.html { redirect_to app_domains_path, notice: "Domain created successfully" }
        format.turbo_stream do
          # Refresh keywords list and clear forms
          @domains = Current.user.domains.includes(:keywords)
          render turbo_stream: [
            turbo_stream.update("bulk_domain_form", ""),
            turbo_stream.update("domain_form", ""),
            turbo_stream.update("bulk_keyword_domain_form", ""),
            turbo_stream.replace("bulk_keywords_list", partial: "app/bulk_wordpress_content_generations/keywords_list", locals: { domains: @domains })
          ]
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @domain = Domain.find(params[:id])
    @domain.destroy
    redirect_to app_domains_path, notice: "Domain deleted successfully"
  end

  private
  def domain_params
    params.require(:domain).permit(:name, :country)
  end
end