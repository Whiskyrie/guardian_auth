# frozen_string_literal: true

class RateLimitService
  class << self
    # Check if request should be rate limited
    # @param operation [String] The mutation name (e.g., 'loginUser', 'registerUser')
    # @param identifier [String] IP address or user ID
    # @param limit [Integer] Maximum requests allowed
    # @param window [ActiveSupport::Duration] Time window for the limit
    # @return [Hash] { allowed: Boolean, remaining: Integer, reset_at: Time }
    def check_and_increment(operation:, identifier:, limit:, window:)
      cache_key = build_cache_key(operation, identifier)

      # Get current data from cache
      cache_data = Rails.cache.read(cache_key)

      if cache_data.nil?
        # First request in window
        cache_data = {
          count: 1,
          first_request_at: Time.current,
          window_end: Time.current + window
        }

        Rails.cache.write(cache_key, cache_data, expires_in: window)

        return {
          allowed: true,
          remaining: limit - 1,
          reset_at: cache_data[:window_end],
          limit: limit
        }
      end

      # Check if we're still in the same window
      if Time.current > cache_data[:window_end]
        # Window expired, reset counter
        cache_data = {
          count: 1,
          first_request_at: Time.current,
          window_end: Time.current + window
        }

        Rails.cache.write(cache_key, cache_data, expires_in: window)

        return {
          allowed: true,
          remaining: limit - 1,
          reset_at: cache_data[:window_end],
          limit: limit
        }
      end

      # Check if limit would be exceeded with this request
      if cache_data[:count] >= limit
        # Log the blocked attempt
        Rails.logger.warn "Rate limit exceeded for #{operation} - Identifier: #{identifier}, Count: #{cache_data[:count] + 1}/#{limit}"

        return {
          allowed: false,
          remaining: 0,
          reset_at: cache_data[:window_end],
          limit: limit
        }
      end

      # Increment counter and save (request is allowed)
      cache_data[:count] += 1
      Rails.cache.write(cache_key, cache_data, expires_in: time_until_reset(cache_data[:window_end]))

      {
        allowed: true,
        remaining: [0, limit - cache_data[:count]].max,
        reset_at: cache_data[:window_end],
        limit: limit
      }
    end

    # Get current rate limit status without incrementing
    # @param operation [String] The mutation name
    # @param identifier [String] IP address or user ID
    # @param limit [Integer] Maximum requests allowed
    # @param window [ActiveSupport::Duration] Time window for the limit
    # @return [Hash] { remaining: Integer, reset_at: Time, limit: Integer }
    def status(operation:, identifier:, limit:, window:)
      cache_key = build_cache_key(operation, identifier)
      cache_data = Rails.cache.read(cache_key)

      if cache_data.nil? || Time.current > cache_data[:window_end]
        return {
          remaining: limit,
          reset_at: Time.current + window,
          limit: limit
        }
      end

      {
        remaining: [0, limit - cache_data[:count]].max,
        reset_at: cache_data[:window_end],
        limit: limit
      }
    end

    # Clear rate limit for a specific operation and identifier
    # @param operation [String] The mutation name
    # @param identifier [String] IP address or user ID
    def clear(operation:, identifier:)
      cache_key = build_cache_key(operation, identifier)
      Rails.cache.delete(cache_key)
    end

    private

    def build_cache_key(operation, identifier)
      "rate_limit:#{operation}:#{identifier}"
    end

    def time_until_reset(reset_time)
      [0, (reset_time - Time.current).to_i].max.seconds
    end
  end
end
