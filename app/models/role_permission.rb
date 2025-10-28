# frozen_string_literal: true

class RolePermission < ApplicationRecord
  # Associations
  belongs_to :role
  belongs_to :permission

  # Validations
  validates :role_id, uniqueness: { scope: :permission_id }

  # Scopes
  scope :for_role, ->(role) { where(role: role) }
  scope :for_permission, ->(permission) { where(permission: permission) }

  # Instance methods
  def permission_name
    permission.name
  end

  def role_name
    role.name
  end
end
