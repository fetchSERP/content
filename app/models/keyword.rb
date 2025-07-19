class Keyword < ApplicationRecord
  enum :search_intent, { informational: 0, navigational: 1, commercial: 2, transactional: 3 }

  belongs_to :keyword, optional: true
  has_many :children, class_name: "Keyword", foreign_key: "keyword_id", dependent: :destroy
  has_one :page, dependent: :destroy
  belongs_to :domain

  validates :name, presence: true, uniqueness: true

end
