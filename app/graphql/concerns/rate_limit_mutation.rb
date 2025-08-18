# frozen_string_literal: true

module RateLimitMutation
  extend ActiveSupport::Concern

  included do
    # Add rate limiting to the mutation
    def self.rate_limited(operation_name = nil)
      @rate_limit_operation = operation_name || name.demodulize.underscore.camelize(:lower)
    end

    # Get the rate limit operation name
    def self.rate_limit_operation
      @rate_limit_operation || name.demodulize.underscore.camelize(:lower)
    end

    # Prepend to execute before the original resolve method
    prepend RateLimitingPrepend
  end

  module RateLimitingPrepend
    # Override resolve to add rate limiting
    def resolve(*args, **kwargs)
      # Get rate limit configuration
      operation_name = self.class.rate_limit_operation
      rate_config = Rails.application.config.rate_limits[operation_name]

      if rate_config
        # Check if IP is whitelisted (skip rate limiting)
        client_ip = extract_client_ip
        if whitelisted_ip?(client_ip)
          return super(*args, **kwargs)
        end

        # Get identifier based on configuration
        identifier = case rate_config[:identifier]
                     when :ip_address
                       client_ip
                     when :user_id
                       context[:current_user]&.id || client_ip # Fall back to IP if no user
                     else
                       client_ip
                     end

        # Check rate limit
        result = RateLimitService.check_and_increment(
          operation: operation_name,
          identifier: identifier.to_s,
          limit: rate_config[:limit],
          window: rate_config[:window]
        )

        # Add rate limit headers to context for response
        add_rate_limit_headers(result)

        # If rate limited, return error
        unless result[:allowed]
          raise GraphQL::ExecutionError.new(
            "Rate limit exceeded. Try again in #{time_until_reset_human(result[:reset_at])}.",
            extensions: {
              code: 'RATE_LIMITED',
              retryAfter: result[:reset_at].to_i
            }
          )
        end
      end

      # Proceed with normal mutation execution
      super(*args, **kwargs)
    end

    private

    def extract_client_ip
      request = context[:request]
      return '127.0.0.1' unless request

      # Try various headers to get real IP
      forwarded_for = request.headers['HTTP_X_FORWARDED_FOR']
      real_ip = request.headers['HTTP_X_REAL_IP']
      
      if forwarded_for.present?
        # Take the first IP in the chain (original client)
        forwarded_for.split(',').first.strip
      elsif real_ip.present?
        real_ip
      else
        request.remote_ip
      end
    end

    def whitelisted_ip?(ip)
      whitelist = Rails.application.config.try(:rate_limit_whitelist)
      return false unless whitelist
      
      whitelist.include?(ip)
    end

    def add_rate_limit_headers(rate_limit_result)
      # Store headers in context to be added by GraphQL controller
      context[:rate_limit_headers] ||= {}
      context[:rate_limit_headers].merge!(
        'X-RateLimit-Limit' => rate_limit_result[:limit].to_s,
        'X-RateLimit-Remaining' => rate_limit_result[:remaining].to_s,
        'X-RateLimit-Reset' => rate_limit_result[:reset_at].to_i.to_s
      )
    end

    def time_until_reset_human(reset_time)
      seconds = (reset_time - Time.current).to_i
      return '0 seconds' if seconds <= 0

      if seconds < 60
        "#{seconds} second#{'s' if seconds != 1}"
      elsif seconds < 3600
        minutes = seconds / 60
        "#{minutes} minute#{'s' if minutes != 1}"
      else
        hours = seconds / 3600
        "#{hours} hour#{'s' if hours != 1}"
      end
    end
  end
end
