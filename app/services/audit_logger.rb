# frozen_string_literal: true

class AuditLogger
  include Singleton

  def initialize
    @logger = Rails.logger
  end

  # Log authentication actions
  def self.log_login(email:, ip:, user_agent:, success:, user: nil, failure_reason: nil)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      failure_reason: failure_reason,
      email: email
    )

    instance.log(
      action: AuditLog::ACTIONS[:authentication][:login],
      resource: AuditLog::RESOURCES[:user],
      resource_id: user&.id,
      user: user,
      metadata: metadata,
      result: success ? 'success' : 'failure'
    )
  end

  def self.log_logout(user:, ip:, user_agent:)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent
    )

    instance.log(
      action: AuditLog::ACTIONS[:authentication][:logout],
      resource: AuditLog::RESOURCES[:user],
      resource_id: user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  def self.log_token_refresh(user:, ip:, user_agent:)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent
    )

    instance.log(
      action: AuditLog::ACTIONS[:authentication][:token_refresh],
      resource: AuditLog::RESOURCES[:token],
      resource_id: user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  # Log authorization actions
  def self.log_access_denied(user:, ip:, user_agent:, resource:, action:, reason: nil)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      failure_reason: reason,
      attempted_action: action
    )

    instance.log(
      action: AuditLog::ACTIONS[:authorization][:access_denied],
      resource: resource,
      user: user,
      metadata: metadata,
      result: 'blocked'
    )
  end

  def self.log_permission_check(user:, ip:, user_agent:, resource:, action:, granted:)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      attempted_action: action
    )

    instance.log(
      action: AuditLog::ACTIONS[:authorization][:permission_check],
      resource: resource,
      user: user,
      metadata: metadata,
      result: granted ? 'success' : 'failure'
    )
  end

  # Log user management actions
  def self.log_user_registration(user:, ip:, user_agent:)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent
    )

    instance.log(
      action: AuditLog::ACTIONS[:user_management][:register],
      resource: AuditLog::RESOURCES[:user],
      resource_id: user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  def self.log_user_update(user:, ip:, user_agent:, previous_values: nil)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      previous_values: previous_values
    )

    instance.log(
      action: AuditLog::ACTIONS[:user_management][:update],
      resource: AuditLog::RESOURCES[:user],
      resource_id: user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  def self.log_password_change(user:, ip:, user_agent:, success:, failure_reason: nil)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      failure_reason: failure_reason
    )

    instance.log(
      action: AuditLog::ACTIONS[:user_management][:password_change],
      resource: AuditLog::RESOURCES[:user],
      resource_id: user.id,
      user: user,
      metadata: metadata,
      result: success ? 'success' : 'failure'
    )
  end

  # Log admin actions
  def self.log_role_change(user:, ip:, user_agent:, target_user:, previous_role:, new_role:)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      previous_values: { role: previous_role },
      new_values: { role: new_role },
      target_user_id: target_user.id
    )

    instance.log(
      action: AuditLog::ACTIONS[:admin][:role_change],
      resource: AuditLog::RESOURCES[:user],
      resource_id: target_user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  def self.log_user_deletion(user:, ip:, user_agent:, target_user:, reason: nil)
    metadata = build_metadata(
      ip: ip,
      user_agent: user_agent,
      target_user_id: target_user.id,
      target_user_email: target_user.email,
      deletion_reason: reason
    )

    instance.log(
      action: AuditLog::ACTIONS[:admin][:user_deletion],
      resource: AuditLog::RESOURCES[:user],
      resource_id: target_user.id,
      user: user,
      metadata: metadata,
      result: 'success'
    )
  end

  # Generic log method
  def self.log(action:, resource:, resource_id: nil, user: nil, metadata: {}, result: 'success')
    instance.log(
      action: action,
      resource: resource,
      resource_id: resource_id,
      user: user,
      metadata: metadata,
      result: result
    )
  end

  def log(action:, resource:, resource_id: nil, user: nil, metadata: {}, result: 'success')
    # Add request context if available
    if Thread.current[:request_context]
      request_context = Thread.current[:request_context]
      metadata[:request_id] = request_context[:request_id] if request_context[:request_id]
      metadata[:ip_address] ||= request_context[:remote_ip] if request_context[:remote_ip]
      metadata[:user_agent] ||= request_context[:user_agent] if request_context[:user_agent]
    end

    AuditLog.log_action(
      action: action,
      resource: resource,
      resource_id: resource_id,
      user: user,
      metadata: metadata,
      result: result
    )
  rescue StandardError => e
    @logger.error "Failed to create audit log: #{e.message}"
    # Don't raise the error to avoid breaking the main operation
  end

  private

  def self.build_metadata(ip:, user_agent:, **additional_data)
    metadata = {
      ip_address: ip,
      user_agent: user_agent,
      timestamp: Time.current.iso8601
    }

    metadata.merge!(additional_data)
    metadata
  end
end
