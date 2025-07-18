class AddWpResponseToWordpressContents < ActiveRecord::Migration[8.0]
  def change
    add_column :wordpress_contents, :wp_response, :jsonb
  end
end
