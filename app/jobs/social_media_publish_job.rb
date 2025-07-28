class SocialMediaPublishJob < ApplicationJob
  queue_as :default

  def perform(social_media_content_id, authentication_provider_id)
    social_media_content = SocialMediaContent.find(social_media_content_id)
    authentication_provider = AuthenticationProvider.find(authentication_provider_id)
    if social_media_content.platform == "linkedin"
      Social::Linkedin::PostService.new(authentication_provider).call(social_media_content.content)
    elsif social_media_content.platform == "x"
      authentication_provider.refresh_x_token!
      Social::X::PostService.new(authentication_provider).call(social_media_content.content)
    end
    social_media_content.update(status: "published")
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{social_media_content.user_id}",
      target: "social_media_content_#{social_media_content.id}",
      partial: "app/social_media_contents/social_media_content",
      locals: { social_media_content: social_media_content }
    )
  end
end
