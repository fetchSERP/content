class AddPublishOnCreateToWordpressContents < ActiveRecord::Migration[8.0]
  def change
    add_column :wordpress_contents, :publish_on_create, :boolean, default: false
  end
end
