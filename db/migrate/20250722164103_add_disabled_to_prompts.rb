class AddDisabledToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompts, :disabled, :boolean, default: false
  end
end
