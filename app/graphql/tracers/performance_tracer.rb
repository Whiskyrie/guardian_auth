# frozen_string_literal: true

module Tracers
  class PerformanceTracer
    def self.trace(key, metadata)
      case key
      when "execute_query"
        start_time = Time.current
        result = yield
        end_time = Time.current
        duration = end_time - start_time

        # Log performance metrics
        log_query_performance(
          query: metadata[:query]&.query_string,
          duration: duration,
          variables: metadata[:variables],
          operation_name: metadata[:operation_name]
        )
        
        result
      when "execute_field"
        start_time = Time.current
        result = yield
        end_time = Time.current
        duration = end_time - start_time
        
        # Log slow field executions (> 100ms)
        if duration > 0.1
          log_slow_field(
            field: metadata[:field]&.graphql_name,
            duration: duration,
            path: metadata[:path]
          )
        end
        
        result
      else
        yield
      end
    end

    private

    def self.log_query_performance(query:, duration:, variables:, operation_name:)
      Rails.logger.info({
        event: 'graphql_query_performance',
        duration_ms: (duration * 1000).round(2),
        query: query&.gsub(/\s+/, ' ')&.strip,
        operation_name: operation_name,
        variables: variables&.keys,
        timestamp: Time.current.iso8601
      }.to_json)

      # Log slow queries (> 5 seconds)
      if duration > 5
        Rails.logger.warn({
          event: 'slow_graphql_query',
          duration_ms: (duration * 1000).round(2),
          query: query,
          operation_name: operation_name,
          timestamp: Time.current.iso8601
        }.to_json)
      end
    end

    def self.log_slow_field(field:, duration:, path:)
      Rails.logger.warn({
        event: 'slow_graphql_field',
        field: field,
        duration_ms: (duration * 1000).round(2),
        path: path,
        timestamp: Time.current.iso8601
      }.to_json)
    end
  end
end
