# frozen_string_literal: true

class HealthController < ApplicationController
  # No authentication required for health checks

  def index
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name
    }
  end

  def detailed
    health_data = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name,
      checks: perform_health_checks
    }

    # Set HTTP status based on overall health
    overall_status = health_data[:checks].all? { |_, check| check[:status] == 'ok' } ? 200 : 503

    render json: health_data, status: overall_status
  end

  private

  def perform_health_checks
    {
      database: check_database,
      redis: check_redis,
      cache: check_cache,
      rate_limiting: check_rate_limiting
    }
  end

  def check_database
    {
      status: 'ok',
      response_time: measure_time { ActiveRecord::Base.connection.execute('SELECT 1') }
    }
  rescue StandardError => e
    {
      status: 'error',
      error: e.message
    }
  end

  def check_redis
    {
      status: 'ok',
      response_time: measure_time do
        Rails.application.config.redis_pool.with(&:ping)
      end
    }
  rescue StandardError => e
    {
      status: 'error',
      error: e.message
    }
  end

  def check_cache
    {
      status: 'ok',
      response_time: measure_time do
        Rails.cache.write('health_check', 'ok', expires_in: 1.minute)
        Rails.cache.read('health_check')
      end
    }
  rescue StandardError => e
    {
      status: 'error',
      error: e.message
    }
  end

  def check_rate_limiting
    {
      status: 'ok',
      response_time: measure_time do
        Rails.application.config.rate_limit_cache_store.write('health_check_rl', 'ok', expires_in: 1.minute)
        Rails.application.config.rate_limit_cache_store.read('health_check_rl')
      end
    }
  rescue StandardError => e
    {
      status: 'error',
      error: e.message
    }
  end

  def measure_time
    start_time = Time.current
    yield
    ((Time.current - start_time) * 1000).round(2) # milliseconds
  end
end
