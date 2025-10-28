# frozen_string_literal: true

class Role < ApplicationRecord
  # Associations
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 255 }

  # Scopes
  scope :system, -> { where(system_role: true) }
  scope :custom, -> { where(system_role: false) }
  scope :ordered, -> { order(:name) }

  # Class methods
  def self.default_user_role
    find_by(name: 'user')
  end

  def self.admin_role
    find_by(name: 'admin')
  end

  # Instance methods
  def permission_names
    permissions.pluck(:resource, :action).map { |resource, action| "#{resource}:#{action}" }
  end

  def has_permission?(resource, action)
    permissions.exists?(resource: resource, action: action)
  end

  def add_permission(resource, action)
    permission = Permission.find_by(resource: resource, action: action)
    return false unless permission

    role_permissions.find_or_create_by(permission: permission)
    true
  end

  def remove_permission(resource, action)
    permission = Permission.find_by(resource: resource, action: action)
    return false unless permission

    role_permissions.where(permission: permission).destroy_all
    true
  end

  def system_role?
    system_role
  end

  def user_count
    users.count
  end

  def to_s
    name
  end
end
