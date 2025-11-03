# frozen_string_literal: true

module Resolvers
  class AuditLogsResolver < Resolvers::BaseResolver
    description "Query audit logs for security monitoring"

    type Types::AuditLogType.connection_type, null: false

    argument :user_id, ID, required: false, description: "Filter by specific user ID"
    argument :action, String, required: false, description: "Filter by specific action"
    argument :resource, String, required: false, description: "Filter by resource type"
    argument :result, String, required: false, description: "Filter by result (success, failure, blocked)"
    argument :start_date, GraphQL::Types::ISO8601Date, required: false, description: "Start date for filtering"
    argument :end_date, GraphQL::Types::ISO8601Date, required: false, description: "End date for filtering"
    argument :recent_hours, Integer, required: false, description: "Filter logs from last N hours"
    argument :ip_address, String, required: false, description: "Filter by IP address"
    argument :failure_reason, String, required: false, description: "Filter by failure reason"

    def resolve(**args)
      # Authorization check
      current_user = context[:current_user]
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
      raise GraphQL::ExecutionError, "Insufficient permissions" unless current_user.has_permission?('audit_logs',
                                                                                                    'read')

      # Start with base query
      query = AuditLog.all

      # Apply filters
      query = apply_filters(query, args)

      # Order by most recent first
      query.order(created_at: :desc)
    end

    private

    def apply_filters(query, args)
      # Filter by user
      if args[:user_id]
        query = query.for_user(User.find(args[:user_id]))
      end

      # Filter by action
      if args[:action]
        query = query.by_action(args[:action])
      end

      # Filter by resource
      if args[:resource]
        query = query.by_resource(args[:resource])
      end

      # Filter by result
      if args[:result]
        query = query.by_result(args[:result])
      end

      # Filter by date range
      if args[:start_date] && args[:end_date]
        query = query.between_dates(args[:start_date], args[:end_date])
      elsif args[:recent_hours]
        query = query.recent(args[:recent_hours])
      end

      # Filter by IP address (requires JSON query)
      if args[:ip_address]
        query = query.where("metadata->>'ip_address' = ?", args[:ip_address])
      end

      # Filter by failure reason (requires JSON query)
      if args[:failure_reason]
        query = query.where("metadata->>'failure_reason' = ?", args[:failure_reason])
      end

      query
    end
  end
end
