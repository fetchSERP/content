class RecurringSocialMediaContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  belongs_to :authentication_provider, optional: true
  has_many :social_media_contents, dependent: :destroy

  enum :platform, { linkedin: 0, x: 1 }
  enum :status, { draft: 0, active: 1, paused: 2 }

  validates :ai_model, presence: true
  validates :keywords, presence: true
  validates :cta_url, presence: true, format: { with: URI.regexp }
  validates :frequency, presence: true, numericality: { greater_than: 0 }
  validates :platform, presence: true
  validates :authentication_provider_id, presence: true, on: :create

  scope :active_campaigns, -> { where(is_active: true) }

  def selected_keywords
    return [] if keywords.blank?
    Keyword.joins(:domain).where(domains: { user: user }, name: keywords)
  end

  def random_keyword
    selected_keywords.sample
  end

  def frequency_minutes
    frequency
  end

  def total_posts_generated
    social_media_contents.count
  end

  def last_post_at
    social_media_contents.order(:created_at).last&.created_at
  end

  def next_post_in
    return "Ready to post" unless last_post_at
    
    next_time = last_post_at + frequency_minutes.minutes
    return "Ready to post" if Time.current >= next_time
    
    diff = (next_time - Time.current).to_i
    
    if diff < 60
      "#{diff} seconds"
    elsif diff < 3600
      "#{diff / 60} minutes"
    elsif diff < 86400
      "#{diff / 3600} hours"
    else
      "#{diff / 86400} days"
    end
  end
end
