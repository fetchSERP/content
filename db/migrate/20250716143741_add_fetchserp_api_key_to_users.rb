class AddFetchserpApiKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :fetchserp_api_key, :string
  end
end
