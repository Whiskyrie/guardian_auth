# frozen_string_literal: true

module GraphQL
  # GraphQL tracer for comprehensive logging and error tracking
  module LoggingTracer
    def self.trace(key, data)
      case key
      when 'execute_query'
        trace_query_execution(data)
      when 'execute_query_lazy'
        trace_query_completion(data)
      else
        yield
      end
    end

    private

    def self.trace_query_execution(data)
      start_time = Time.current
      query = data[:query]
      
      # Extract operation details
      operation_name = query.operation_name
      operation_type = query.selected_operation&.operation_type || 'unknown'
      
      # Log the incoming request
      GraphqlLogger.log_query(
        query: query.query_string,
        variables: query.variables,
        operation_name: operation_name,
        operation_type: operation_type,
        context: sanitized_context(query.context)
      )

      result = yield
      
      # Calculate duration
      duration = ((Time.current - start_time) * 1000).round(2)

      # Log completion
      if result.key?('errors') && result['errors'].any?
        log_errors(result['errors'], query, duration)
      else
        GraphqlLogger.log_query_success(
          operation_name: operation_name,
          operation_type: operation_type,
          duration: duration,
          data_present: result.key?('data') && result['data'].present?
        )
      end

      result
    rescue StandardError => e
      duration = ((Time.current - start_time) * 1000).round(2)
      
      # Log unexpected errors
      GraphqlLogger.log_error(
        error: e,
        query: query.query_string,
        variables: query.variables,
        context: sanitized_context(query.context),
        duration: duration
      )

      raise
    end

    def self.trace_query_completion(data)
      yield
    end

    def self.log_errors(errors, query, duration)
      errors.each do |error|
        error_details = {
          message: error['message'],
          path: error['path'],
          locations: error['locations'],
          extensions: error['extensions']
        }

        if error['extensions']&.dig('code')
          # This is one of our custom errors
          GraphqlLogger.log_business_error(
            error_code: error['extensions']['code'],
            error_message: error['message'],
            error_path: error['path'],
            query: query.query_string,
            variables: query.variables,
            context: sanitized_context(query.context),
            duration: duration
          )
        else
          # This is an unexpected error
          GraphqlLogger.log_error(
            error: StandardError.new(error['message']),
            query: query.query_string,
            variables: query.variables,
            context: sanitized_context(query.context),
            duration: duration,
            additional_info: error_details
          )
        end
      end
    end

    def self.sanitized_context(context)
      return {} unless context

      # Remove sensitive information from context for logging
      sanitized = context.to_h.except(:current_user_token, :request)
      
      # Add safe user information if available
      if context[:current_user]
        sanitized[:user_id] = context[:current_user].id
        sanitized[:user_email] = context[:current_user].email
      end

      # Add request information without sensitive headers
      if context[:request]
        sanitized[:request_ip] = context[:request].remote_ip
        sanitized[:user_agent] = context[:request].user_agent
        sanitized[:request_method] = context[:request].method
      end

      sanitized
    end
  end
end
