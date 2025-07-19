class FetchKeywordsJob < ApplicationJob
  queue_as :default

  def perform(domain)
    client = FetchSERP::Client.new(api_key: domain.user.fetchserp_api_key)
    keywords = client.keywords_suggestions(url: "https://#{domain.name}", country: domain.country)
    keywords["data"]["keywords_suggestions"].each do |keyword|
      domain.keywords.create(name: keyword["keyword"])
    end
  end
end