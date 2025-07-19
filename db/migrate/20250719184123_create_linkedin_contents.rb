class CreateLinkedinContents < ActiveRecord::Migration[8.0]
  def change
    create_table :linkedin_contents do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.integer :status, default: 0
      t.string :ai_model
      t.references :prompt, null: false, foreign_key: true
      t.string :cta_url
      t.string :keyword
      t.jsonb :linkedin_response

      t.timestamps
    end
  end
end
