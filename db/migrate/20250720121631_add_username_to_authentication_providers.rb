class AddUsernameToAuthenticationProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :authentication_providers, :username, :string
  end
end
