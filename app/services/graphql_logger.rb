# frozen_string_literal: true

class GraphqlLogger
  include Singleton

  def initialize
    @logger = Logger.new(
      Rails.root.join('log', 'graphql.log'),
      10, # Keep 10 old log files
      10.megabytes # Rotate when file reaches 10MB
    )
    @logger.level = Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
  end

  def self.log_query(query:, variables:, operation_name:, context:, duration: nil, result: nil)
    instance.log_query(
      query: query,
      variables: variables,
      operation_name: operation_name,
      context: context,
      duration: duration,
      result: result
    )
  end

  def self.log_error(error:, query:, context:, **additional_data)
    instance.log_error(
      error: error,
      query: query,
      context: context,
      **additional_data
    )
  end

  def self.log_authorization_failure(user:, action:, resource:, context:)
    instance.log_authorization_failure(
      user: user,
      action: action,
      resource: resource,
      context: context
    )
  end

  def self.log_rate_limit(identifier:, limit:, current_count:, context:)
    instance.log_rate_limit(
      identifier: identifier,
      limit: limit,
      current_count: current_count,
      context: context
    )
  end

  def log_query(query:, variables:, operation_name:, context:, duration: nil, result: nil)
    log_data = {
      event: 'graphql_query',
      operation_name: operation_name,
      query_complexity: calculate_complexity(result),
      duration_ms: duration&.round(2),
      user_id: context[:current_user]&.id,
      ip_address: extract_ip(context),
      user_agent: extract_user_agent(context),
      variables_keys: variables&.keys,
      timestamp: Time.current.iso8601
    }

    # Add error information if present
    if result&.key?('errors') && result['errors']&.any?
      log_data[:errors_count] = result['errors'].length
      log_data[:error_codes] = extract_error_codes(result['errors'])
    end

    # Log performance warnings
    if duration && duration > 5000 # 5 seconds
      log_data[:performance_warning] = 'slow_query'
      @logger.warn(log_data.to_json)
    else
      @logger.info(log_data.to_json)
    end
  end

  def log_error(error:, query:, context:, **additional_data)
    log_data = {
      event: 'graphql_error',
      error_class: error.class.name,
      error_message: error.message,
      error_code: extract_error_code(error),
      query_string: truncate_query(query),
      user_id: context[:current_user]&.id,
      ip_address: extract_ip(context),
      user_agent: extract_user_agent(context),
      timestamp: Time.current.iso8601,
      **additional_data
    }

    # Add backtrace for non-GraphQL errors
    if !error.is_a?(GraphQL::ExecutionError)
      log_data[:backtrace] = error.backtrace&.first(10)
    end

    @logger.error(log_data.to_json)

    # Also log to security logger for authentication/authorization errors
    if security_related_error?(error)
      SecurityLogger.log_security_event(
        event: 'graphql_security_error',
        user_id: context[:current_user]&.id,
        ip: extract_ip(context),
        user_agent: extract_user_agent(context),
        details: {
          error_class: error.class.name,
          error_message: error.message,
          error_code: extract_error_code(error)
        }
      )
    end
  end

  def log_authorization_failure(user:, action:, resource:, context:)
    log_data = {
      event: 'graphql_authorization_failure',
      user_id: user&.id,
      user_role: user&.role,
      action: action,
      resource_type: resource.class.name,
      resource_id: resource.respond_to?(:id) ? resource.id : nil,
      ip_address: extract_ip(context),
      user_agent: extract_user_agent(context),
      timestamp: Time.current.iso8601
    }

    @logger.warn(log_data.to_json)

    # Also log to security logger
    SecurityLogger.log_authorization_failure(
      user_id: user&.id,
      ip: extract_ip(context),
      user_agent: extract_user_agent(context),
      resource: "#{resource.class.name}##{action}",
      reason: 'insufficient_permissions'
    )
  end

  def log_rate_limit(identifier:, limit:, current_count:, context:)
    log_data = {
      event: 'graphql_rate_limit',
      identifier: identifier,
      limit: limit,
      current_count: current_count,
      user_id: context[:current_user]&.id,
      ip_address: extract_ip(context),
      user_agent: extract_user_agent(context),
      timestamp: Time.current.iso8601
    }

    @logger.warn(log_data.to_json)
  end

  private

  def extract_ip(context)
    context[:request]&.remote_ip || context[:ip_address]
  end

  def extract_user_agent(context)
    context[:request]&.user_agent || context[:user_agent]
  end

  def extract_error_code(error)
    if error.respond_to?(:error_code)
      error.error_code
    elsif error.is_a?(GraphQL::ExecutionError) && error.extensions['code']
      error.extensions['code']
    else
      'UNKNOWN'
    end
  end

  def extract_error_codes(errors)
    errors.map { |error| error.dig('extensions', 'code') }.compact.uniq
  end

  def calculate_complexity(result)
    # Placeholder for complexity calculation
    # This would need to be integrated with GraphQL's complexity analysis
    result&.dig('extensions', 'complexity') || 'unknown'
  end

  def truncate_query(query)
    return nil unless query
    
    query.length > 500 ? "#{query[0..497]}..." : query
  end

  def security_related_error?(error)
    return true if error.is_a?(Errors::AuthenticationError)
    return true if error.is_a?(Errors::AuthorizationError)
    return true if error.is_a?(Pundit::NotAuthorizedError)
    return true if error.is_a?(JWT::DecodeError)
    
    false
  end
end
