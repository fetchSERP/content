class Keyword < ApplicationRecord
  enum :search_intent, { informational: 0, navigational: 1, commercial: 2, transactional: 3 }

  belongs_to :keyword, optional: true
  has_one :page, dependent: :destroy

  after_create :create_seo_page
  after_create :create_long_tail_keywords, unless: :is_long_tail?

  validates :name, presence: true, uniqueness: true

  private

  def create_seo_page
    CreateSeoPageJob.perform_later(self)
  end

  def create_long_tail_keywords
    CreateSeoKeywordsJob.perform_later(self)
  end
end
