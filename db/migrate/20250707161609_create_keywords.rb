class CreateKeywords < ActiveRecord::Migration[8.0]
  def change
    create_table :keywords do |t|
      t.string :name
      t.boolean :is_long_tail
      t.references :keyword, null: true, foreign_key: true
      t.integer :search_intent, default: 0

      t.timestamps
    end
  end
end
