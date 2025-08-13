class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[user admin] }

  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role ||= "user"
  end
end
