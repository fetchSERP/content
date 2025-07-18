class WordpressContent < ApplicationRecord
  belongs_to :user
  belongs_to :prompt
  enum :status, { draft: 0, publish: 1 }
  after_create_commit :generate_content

  private

  def generate_content
    WordpressContentGeneratorJob.perform_later(self)
  end
end
