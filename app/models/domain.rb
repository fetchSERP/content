class Domain < ApplicationRecord
  belongs_to :user
  has_many :keywords, dependent: :destroy

  after_create_commit :fetch_keywords

  private
  def fetch_keywords
    FetchKeywordsJob.perform_later(self)
  end
end
