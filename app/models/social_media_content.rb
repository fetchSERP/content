class SocialMediaContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  enum :status, { draft: 0, published: 1 }
  enum :platform, { linkedin: 0, x: 1 }

  def generate!
    GenerateSocialMediaContentJob.perform_later(self)
  end

end
