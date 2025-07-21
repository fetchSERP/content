class CreateSocialMediaContents < ActiveRecord::Migration[8.0]
  def change
    create_table :social_media_contents do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.integer :status, default: 0
      t.string :ai_model
      t.references :prompt, null: false, foreign_key: true
      t.string :cta_url
      t.string :keyword
      t.jsonb :social_media_response
      t.integer :platform, default: 0

      t.timestamps
    end
  end
end
