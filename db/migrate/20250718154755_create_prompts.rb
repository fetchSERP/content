class CreatePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :prompts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :target, null: false, default: 0
      t.text :user_prompt
      t.text :system_prompt

      t.timestamps
    end
  end
end
