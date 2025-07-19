class Prompt < ApplicationRecord
  belongs_to :user
  has_many :wordpress_contents, dependent: :destroy
  has_many :linkedin_contents, dependent: :destroy
  enum :target, { wordpress: 0, x: 1, linkedin: 2 }
  
  validates :target, presence: true
  validates :user_prompt, presence: true, length: { minimum: 10, maximum: 5000 }
  validates :system_prompt, presence: true, length: { minimum: 10, maximum: 2000 }
end
