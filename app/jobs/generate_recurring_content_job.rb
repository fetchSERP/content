class GenerateRecurringContentJob < ApplicationJob
  queue_as :default

  def perform(recurring_content_id)
    recurring_content = RecurringSocialMediaContent.find(recurring_content_id)
    
    # Skip if inactive
    unless recurring_content.is_active?
      Rails.logger.info "Skipping inactive recurring content: #{recurring_content.id}"
      return
    end
    
    # Generate content
    generate_content_for(recurring_content)
    
    # Schedule next job based on frequency
    Rails.logger.info "Scheduling next job for recurring content #{recurring_content.id} in #{recurring_content.frequency} minutes"
    self.class.set(wait: recurring_content.frequency.minutes)
               .perform_later(recurring_content.id)
  end
  
  private
  
  def generate_content_for(recurring_content)
    # Random keyword selection from array
    random_keyword = recurring_content.random_keyword
    
    unless random_keyword
      Rails.logger.error "No keywords found for recurring content: #{recurring_content.id}"
      return
    end
    
    Rails.logger.info "Generating content for recurring content #{recurring_content.id} with keyword: #{random_keyword.name}"
    
    # Create social media content
    content = recurring_content.user.social_media_contents.create!(
      platform: recurring_content.platform,
      keyword: random_keyword.name,
      prompt: recurring_content.prompt,
      ai_model: recurring_content.ai_model,
      cta_url: recurring_content.cta_url,
      recurring_social_media_content: recurring_content
    )
    
    # Generate and publish automatically
    content.generate_and_publish!
    
    Rails.logger.info "Successfully created social media content: #{content.id}"
  rescue => e
    Rails.logger.error "Failed to generate content for recurring content #{recurring_content.id}: #{e.message}"
    # Don't re-raise to prevent job from failing and stopping the chain
  end
end 