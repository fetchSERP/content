class SocialMediaContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  enum :status, { draft: 0, published: 1 }
  enum :platform, { linkedin: 0, x: 1 }
  validates :platform, presence: true
  validates :prompt_id, presence: true
  validates :cta_url, presence: true
  validates :keyword, presence: true
  validates :ai_model, presence: true

  def generate!
    GenerateSocialMediaContentJob.perform_later(self)
  end

end
