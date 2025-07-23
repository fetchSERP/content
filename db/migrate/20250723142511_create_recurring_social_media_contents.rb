class CreateRecurringSocialMediaContents < ActiveRecord::Migration[8.0]
  def change
    create_table :recurring_social_media_contents do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.integer :status, default: 0
      t.string :ai_model, default: "gpt-4o"
      t.references :prompt, null: false, foreign_key: true
      t.string :cta_url
      t.string :keywords, array: true, default: []
      t.integer :platform, default: 0
      t.integer :frequency, default: 120
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
