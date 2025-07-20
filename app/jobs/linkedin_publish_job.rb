class LinkedinPublishJob < ApplicationJob
  queue_as :default

  def perform(linkedin_content_id, authentication_provider_id)
    linkedin_content = LinkedinContent.find(linkedin_content_id)
    authentication_provider = AuthenticationProvider.find(authentication_provider_id)
    Social::Linkedin::PostService.new(authentication_provider).call(linkedin_content.content)
  end
end