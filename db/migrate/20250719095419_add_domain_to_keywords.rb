class AddDomainToKeywords < ActiveRecord::Migration[8.0]
  def change
    add_reference :keywords, :domain, null: false, foreign_key: true
  end
end
