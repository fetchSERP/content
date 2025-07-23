class SocialMediaContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  belongs_to :recurring_social_media_content, optional: true
  
  enum :status, { draft: 0, published: 1 }
  enum :platform, { linkedin: 0, x: 1 }
  
  validates :platform, presence: true
  validates :prompt_id, presence: true
  validates :cta_url, presence: true
  validates :keyword, presence: true
  validates :ai_model, presence: true

  scope :from_recurring, -> { where.not(recurring_social_media_content_id: nil) }
  scope :manual, -> { where(recurring_social_media_content_id: nil) }

  def generate!
    GenerateSocialMediaContentJob.perform_later(self)
  end

  def generate_and_publish!
    # For recurring content, we want to generate and auto-publish
    if recurring_social_media_content.present?
      GenerateSocialMediaContentJob.perform_later(self, auto_publish: true)
    else
      generate!
    end
  end

  def from_recurring_campaign?
    recurring_social_media_content.present?
  end
end
