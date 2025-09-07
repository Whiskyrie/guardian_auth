# frozen_string_literal: true

module Types
  class AuditLogType < Types::BaseObject
    description "Audit log entry for security and compliance tracking"

    field :id, ID, null: false, description: "Unique identifier for the audit log entry"
    field :action, String, null: false, description: "Action performed (login, logout, register, etc)"
    field :resource, String, null: false, description: "Resource type (User, Token, etc)"
    field :resource_id, String, null: true, description: "ID of the affected resource"
    field :metadata, Types::JsonType, null: true, description: "Additional metadata including IP, user agent, etc"
    field :result, String, null: false, description: "Result of the action (success, failure, blocked)"
    field :created_at, Types::DateTimeType, null: false, description: "When the action occurred"
    field :user, Types::UserType, null: true, description: "User who performed the action"
    
    # Computed fields for easier access to metadata
    field :ip_address, String, null: true, description: "IP address from which the action originated"
    field :user_agent, String, null: true, description: "User agent string from the request"
    field :request_id, String, null: true, description: "Unique request identifier"
    field :failure_reason, String, null: true, description: "Reason for failure if applicable"
    field :previous_values, Types::JsonType, null: true, description: "Previous values before update"
    
    # Authorization
    def self.authorized?(object, context)
      # Only admins can view audit logs
      user = context[:current_user]
      user && user.has_permission?('audit_logs', 'read')
    end

    def ip_address
      object.metadata&.dig('ip_address')
    end

    def user_agent
      object.metadata&.dig('user_agent')
    end

    def request_id
      object.metadata&.dig('request_id')
    end

    def failure_reason
      object.metadata&.dig('failure_reason')
    end

    def previous_values
      object.metadata&.dig('previous_values')
    end
  end
end
