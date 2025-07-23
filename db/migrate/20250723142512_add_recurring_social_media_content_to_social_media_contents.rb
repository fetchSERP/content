class AddRecurringSocialMediaContentToSocialMediaContents < ActiveRecord::Migration[8.0]
  def change
    add_reference :social_media_contents, :recurring_social_media_content, 
                  null: true, foreign_key: true, index: true
  end
end 