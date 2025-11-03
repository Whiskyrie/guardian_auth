# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    # Set up callbacks for automatic audit logging
    after_create :log_creation, if: :should_audit?
    after_update :log_update, if: :should_audit?
    after_destroy :log_deletion, if: :should_audit?
  end

  private

  def log_creation
    AuditLogger.log(
      action: audit_action_for(:create),
      resource: self.class.name,
      resource_id: id,
      user: audit_user,
      metadata: audit_metadata_for(:create),
      result: 'success'
    )
  end

  def log_update
    # Only log if there are actual changes
    return unless saved_changes?

    AuditLogger.log(
      action: audit_action_for(:update),
      resource: self.class.name,
      resource_id: id,
      user: audit_user,
      metadata: audit_metadata_for(:update),
      result: 'success'
    )
  end

  def log_deletion
    AuditLogger.log(
      action: audit_action_for(:destroy),
      resource: self.class.name,
      resource_id: id,
      user: audit_user,
      metadata: audit_metadata_for(:destroy),
      result: 'success'
    )
  end

  def should_audit?
    # Override this method in your model to control when to audit
    true
  end

  def audit_action_for(action)
    # Override this method to customize action names
    case action
    when :create then 'create'
    when :update then 'update'
    when :destroy then 'delete'
    else action.to_s
    end
  end

  def audit_user
    # Override this method to set the user performing the action
    # Default: try to get current user from thread or return nil
    Thread.current[:current_user] || (defined?(Current) && Current&.user)
  end

  def audit_metadata_for(action)
    metadata = {
      model: self.class.name,
      action: action,
      timestamp: Time.current.iso8601
    }

    case action
    when :create
      metadata[:new_values] = attributes.except('created_at', 'updated_at')
    when :update
      metadata[:previous_values] = saved_changes.transform_values(&:first)
      metadata[:new_values] = saved_changes.transform_values(&:last)
    when :destroy
      metadata[:deleted_values] = attributes.except('created_at', 'updated_at')
    end

    # Add request context if available
    if Thread.current[:request_context]
      request_context = Thread.current[:request_context]
      metadata[:request_id] = request_context[:request_id] if request_context[:request_id]
      metadata[:ip_address] = request_context[:remote_ip] if request_context[:remote_ip]
      metadata[:user_agent] = request_context[:user_agent] if request_context[:user_agent]
    end

    metadata
  end
end
