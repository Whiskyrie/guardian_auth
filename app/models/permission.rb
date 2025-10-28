# frozen_string_literal: true

class Permission < ApplicationRecord
  # Associations
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  # Validations
  validates :resource, presence: true, length: { maximum: 50 }
  validates :action, presence: true, length: { maximum: 50 }
  validates :action, uniqueness: { scope: :resource }
  validates :description, length: { maximum: 255 }

  # Scopes
  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :ordered, -> { order(:resource, :action) }

  # Instance methods
  def name
    "#{resource}:#{action}"
  end

  def to_s
    name
  end

  def display_name
    description.presence || name
  end

  # Class methods
  def self.find_by_name(permission_name)
    resource, action = permission_name.split(':', 2)
    find_by(resource: resource, action: action)
  end

  def self.resources
    distinct.pluck(:resource).sort
  end

  def self.actions_for_resource(resource)
    where(resource: resource).pluck(:action).sort
  end

  def self.grouped_by_resource
    all.group_by(&:resource)
  end
end
