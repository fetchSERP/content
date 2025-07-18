class App::WordpressWebsitesController < App::ApplicationController
  def index
    @wordpress_websites = Current.user.wordpress_websites
  end

  def new
    @wordpress_website = WordpressWebsite.new
  end

  def create
    @wordpress_website = Current.user.wordpress_websites.build(wordpress_website_params)
    if @wordpress_website.save
      redirect_to app_wordpress_websites_path, notice: "WordPress website created successfully"
    else
      render :new
    end
  end

  private

  def wordpress_website_params
    params.require(:wordpress_website).permit(:url, :username, :password)
  end
end