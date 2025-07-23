class FetchKeywordsJob < ApplicationJob
  queue_as :default

  def perform(domain)
    client = FetchSERP::Client.new(api_key: domain.user.fetchserp_api_key)
    keywords = client.keywords_suggestions(url: "https://#{domain.name}", country: domain.country)
    keywords["data"]["keywords_suggestions"].each do |keyword|
      domain.keywords.create(name: keyword["keyword"])
    end
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{domain.user_id}",
      target: "domain_#{domain.id}",
      partial: "app/domains/domain",
      locals: { domain: domain }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{domain.user_id}",
      target: "bulk_keywords_list",
      partial: "app/bulk_wordpress_content_generations/keywords_list",
      locals: { domains: domain.user.domains.includes(:keywords) }
    )
    broadcast_credit(domain.user)
  end
end
