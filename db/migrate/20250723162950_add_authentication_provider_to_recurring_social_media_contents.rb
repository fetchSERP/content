class AddAuthenticationProviderToRecurringSocialMediaContents < ActiveRecord::Migration[8.0]
  def change
    add_reference :recurring_social_media_contents, :authentication_provider, null: true, foreign_key: true
  end
end
