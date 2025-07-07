class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages do |t|
      t.references :keyword, null: false, foreign_key: true
      t.string :slug
      t.text :meta_title
      t.text :meta_description
      t.text :headline
      t.text :subheading
      t.text :content

      t.timestamps
    end
  end
end
