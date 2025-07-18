class CreateAuthenticationProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :authentication_providers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :uid
      t.string :token

      t.timestamps
    end
  end
end
