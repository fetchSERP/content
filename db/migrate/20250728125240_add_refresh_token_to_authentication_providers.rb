class AddRefreshTokenToAuthenticationProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :authentication_providers, :refresh_token, :string
    add_column :authentication_providers, :expires_at, :datetime
  end
end
