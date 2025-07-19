class WordpressContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  enum :status, { draft: 0, publish: 1 }

  def generate_content!
    GenerateWordpressContentJob.perform_later(self)
  end
end
