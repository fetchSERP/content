class LinkedinContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  enum :status, { draft: 0, published: 1 }
end
