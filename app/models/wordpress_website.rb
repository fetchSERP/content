class WordpressWebsite < ApplicationRecord
  belongs_to :user
  validates :url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :username, presence: true
  validates :password, presence: true
end
