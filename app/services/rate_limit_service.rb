class RateLimitService
  # Lua script: INCR atômico + EXPIRE apenas na primeira chamada + TTL em uma transação
  INCR_WITH_EXPIRE = <<~LUA.freeze
    local count = redis.call('INCR', KEYS[1])
    if count == 1 then
      redis.call('EXPIRE', KEYS[1], ARGV[1])
    end
    local ttl = redis.call('TTL', KEYS[1])
    return {count, ttl}
  LUA

  class << self
    def check_and_increment(operation:, identifier:, limit:, window:)
      key = build_cache_key(operation, identifier)
      window_seconds = window.to_i

      count, ttl = redis_eval(key, window_seconds)

      reset_at = Time.current + [ttl, 0].max.seconds
      allowed = count <= limit

      unless allowed
        Rails.logger.warn "Rate limit exceeded for #{operation} - Identifier: #{identifier}, " \
                          "Count: #{count}/#{limit}"
      end

      { allowed: allowed, remaining: [0, limit - count].max, reset_at: reset_at, limit: limit }
    rescue StandardError => e
      Rails.logger.error "RateLimitService error: #{e.message}"
      { allowed: true, remaining: limit, reset_at: Time.current + window, limit: limit }
    end

    def status(operation:, identifier:, limit:, window:)
      key = build_cache_key(operation, identifier)

      Rails.application.config.redis_pool.with do |redis|
        count = redis.get(key).to_i
        ttl = [redis.ttl(key), 0].max

        { remaining: [0, limit - count].max, reset_at: Time.current + ttl.seconds, limit: limit }
      end
    rescue StandardError => e
      Rails.logger.error "RateLimitService#status error: #{e.message}"
      { remaining: limit, reset_at: Time.current + window, limit: limit }
    end

    def clear(operation:, identifier:)
      key = build_cache_key(operation, identifier)
      Rails.application.config.redis_pool.with { |redis| redis.del(key) }
    end

    private

    def build_cache_key(operation, identifier)
      "rate_limit:#{operation}:#{identifier}"
    end

    def redis_eval(key, window_seconds)
      Rails.application.config.redis_pool.with do |redis|
        result = redis.eval(INCR_WITH_EXPIRE, keys: [key], argv: [window_seconds])
        [result[0].to_i, result[1].to_i]
      end
    end
  end
end
