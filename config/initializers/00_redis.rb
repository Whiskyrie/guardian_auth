# frozen_string_literal: true

require 'connection_pool'
require 'redis'

# Redis configuration for different purposes
# This file is loaded first (00_) to ensure Redis is available for other initializers
Rails.application.configure do
  # Main Redis connection pool
  config.redis_pool = ConnectionPool.new(size: 10, timeout: 5) do
    Redis.new(
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
      driver: :hiredis,
      connect_timeout: 0.2,
      read_timeout: 1.0,
      write_timeout: 0.5,
      reconnect_attempts: 3
    )
  end

  # Dedicated Redis cache store for rate limiting
  config.rate_limit_cache_store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_RATE_LIMIT_URL', 'redis://localhost:6379/1'),
    pool: { size: 5, timeout: 5 },
    error_handler: ->(method:, returning:, exception:) {
      Rails.logger.error "Redis cache error in #{method}: #{exception.message}"
    }
  )

  # Security cache for fail2ban/allow2ban
  config.security_cache_store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_SECURITY_URL', 'redis://localhost:6379/2'),
    pool: { size: 5, timeout: 5 }
  )
end
