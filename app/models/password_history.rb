class PasswordHistory < ApplicationRecord
  belongs_to :user

  validates :password_digest, presence: true
end
