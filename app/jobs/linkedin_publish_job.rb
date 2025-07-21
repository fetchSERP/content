class LinkedinPublishJob < ApplicationJob
  queue_as :default

  def perform(linkedin_content_id, authentication_provider_id)
    linkedin_content = LinkedinContent.find(linkedin_content_id)
    authentication_provider = AuthenticationProvider.find(authentication_provider_id)
    Social::Linkedin::PostService.new(authentication_provider).call(linkedin_content.content)
    linkedin_content.update(status: "published")
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{linkedin_content.user_id}",
      target: "linkedin_content_#{linkedin_content.id}",
      partial: "app/linkedin_contents/linkedin_content",
      locals: { linkedin_content: linkedin_content }
    )
  end
end
