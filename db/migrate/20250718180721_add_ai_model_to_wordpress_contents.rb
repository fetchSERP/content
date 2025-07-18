class AddAiModelToWordpressContents < ActiveRecord::Migration[8.0]
  def change
    add_column :wordpress_contents, :ai_model, :string
  end
end
