class AddPromptToWordpressContents < ActiveRecord::Migration[8.0]
  def change
    add_reference :wordpress_contents, :prompt, null: false, foreign_key: true
  end
end
