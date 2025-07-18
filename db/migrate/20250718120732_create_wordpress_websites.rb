class CreateWordpressWebsites < ActiveRecord::Migration[8.0]
  def change
    create_table :wordpress_websites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url
      t.string :username
      t.string :password

      t.timestamps
    end
  end
end
