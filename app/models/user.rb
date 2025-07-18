class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authentication_providers, dependent: :destroy
  has_many :wordpress_websites, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
