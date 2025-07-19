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
      redirect_to app_domains_path, notice: "Domain created successfully"
    else
      render :new
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