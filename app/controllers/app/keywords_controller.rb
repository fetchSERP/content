class App::KeywordsController < App::ApplicationController
  def index
    @keywords = Keyword.joins(:domain).where(domains: { user: Current.user }).includes(:domain)
    @domains = Current.user.domains.includes(:keywords)
  end
end