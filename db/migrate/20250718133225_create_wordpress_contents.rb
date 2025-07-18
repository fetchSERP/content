class CreateWordpressContents < ActiveRecord::Migration[8.0]
  def change
    create_table :wordpress_contents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.integer :status, null: false, default: 0
      t.string :keyword
      t.string :cta_url

      t.timestamps
    end
  end
end
