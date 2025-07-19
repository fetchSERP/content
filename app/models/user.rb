class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :authentication_providers, dependent: :destroy
  has_many :wordpress_websites, dependent: :destroy
  has_many :wordpress_contents, dependent: :destroy
  has_many :prompts, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :linkedin_contents, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
