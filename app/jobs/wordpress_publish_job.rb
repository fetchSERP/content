class WordpressPublishJob < ApplicationJob
  queue_as :default

  def perform(wordpress_content_id, wordpress_website_id)
    wordpress_content = WordpressContent.find(wordpress_content_id)
    wordpress_website = WordpressWebsite.find(wordpress_website_id)

    Rails.logger.info "Publishing WordPress content #{wordpress_content.id} to website #{wordpress_website.url}"

    # Prepare the payload for WordPress API
    payload = {
      title: wordpress_content.title,
      content: wordpress_content.content,
      status: "publish",
      excerpt: wordpress_content.content&.truncate(160) # Optional: Create excerpt from content
    }

    begin
      # Use the WordPress Post Service to publish
      service = Wordpress::PostService.new(wordpress_website)
      response = service.call(payload)

      # Update the content status to published
      wordpress_content.update!(status: :publish, wp_response: response)

      Turbo::StreamsChannel.broadcast_replace_to(
        "streaming_channel_#{wordpress_content.user_id}",
        target: "wordpress_content_#{wordpress_content.id}",
        partial: "app/wordpress_contents/wordpress_content",
        locals: { wordpress_content: wordpress_content }
      )

      Rails.logger.info "Successfully published content to WordPress. Post ID: #{response['id']}"

    rescue => e
      Rails.logger.error "Failed to publish WordPress content: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # You could add notification logic here to inform the user of the failure
      raise e
    end
  end
end
