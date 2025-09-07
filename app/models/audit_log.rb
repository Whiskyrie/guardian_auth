# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  
  # Validations
  validates :action, presence: true
  validates :resource, presence: true
  validates :result, presence: true, inclusion: { in: %w[success failure blocked] }
  
  # Scopes
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(resource) { where(resource: resource) }
  scope :by_result, ->(result) { where(result: result) }
  scope :successful, -> { where(result: 'success') }
  scope :failed, -> { where(result: 'failure') }
  scope :blocked, -> { where(result: 'blocked') }
  scope :recent, ->(hours = 24) { where('created_at >= ?', hours.hours.ago) }
  scope :between_dates, ->(start_date, end_date) { where(created_at: start_date.beginning_of_day..end_date.end_of_day) }
  
  # Constants for actions
  ACTIONS = {
    authentication: {
      login: 'login',
      logout: 'logout',
      token_refresh: 'token_refresh'
    },
    authorization: {
      access_denied: 'access_denied',
      permission_check: 'permission_check'
    },
    user_management: {
      register: 'register',
      update: 'update',
      password_change: 'password_change'
    },
    admin: {
      role_change: 'role_change',
      user_deletion: 'user_deletion'
    }
  }.freeze
  
  # Constants for resources
  RESOURCES = {
    user: 'User',
    token: 'Token',
    role: 'Role',
    permission: 'Permission'
  }.freeze
  
  # Class methods for creating audit logs
  def self.log_action(action:, resource:, resource_id: nil, user: nil, metadata: {}, result: 'success')
    create!(
      user: user,
      action: action,
      resource: resource,
      resource_id: resource_id,
      metadata: metadata,
      result: result
    )
  end
  
  # Helper methods for metadata
  def ip_address
    metadata&.dig('ip_address')
  end
  
  def user_agent
    metadata&.dig('user_agent')
  end
  
  def request_id
    metadata&.dig('request_id')
  end
  
  def failure_reason
    metadata&.dig('failure_reason')
  end
  
  def previous_values
    metadata&.dig('previous_values')
  end
end
