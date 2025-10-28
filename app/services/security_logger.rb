# frozen_string_literal: true

class SecurityLogger
  include Singleton

  def initialize
    @logger = Logger.new(
      Rails.root.join('log', 'security.log'),
      10, # Keep 10 old log files
      10.megabytes # Rotate when file reaches 10MB
    )
    @logger.level = Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
  end

  def self.log_login_attempt(email:, ip:, user_agent:, success:, failure_reason: nil)
    instance.log_login_attempt(
      email: email,
      ip: ip,
      user_agent: user_agent,
      success: success,
      failure_reason: failure_reason
    )
  end

  def self.log_password_change(user_id:, ip:, user_agent:, success:)
    instance.log_password_change(
      user_id: user_id,
      ip: ip,
      user_agent: user_agent,
      success: success
    )
  end

  def self.log_suspicious_activity(ip:, activity:, details: {})
    instance.log_suspicious_activity(
      ip: ip,
      activity: activity,
      details: details
    )
  end

  def self.log_rate_limit_exceeded(ip:, endpoint:, limit:)
    instance.log_rate_limit_exceeded(
      ip: ip,
      endpoint: endpoint,
      limit: limit
    )
  end

  def log_login_attempt(email:, ip:, user_agent:, success:, failure_reason: nil)
    message = {
      event: 'login_attempt',
      email: email,
      ip: ip,
      user_agent: user_agent,
      success: success,
      failure_reason: failure_reason,
      timestamp: Time.current.iso8601
    }.compact

    if success
      @logger.info(message.to_json)
    else
      @logger.warn(message.to_json)
    end
  end

  def log_password_change(user_id:, ip:, user_agent:, success:)
    message = {
      event: 'password_change',
      user_id: user_id,
      ip: ip,
      user_agent: user_agent,
      success: success,
      timestamp: Time.current.iso8601
    }

    @logger.info(message.to_json)
  end

  def log_suspicious_activity(ip:, activity:, details: {})
    message = {
      event: 'suspicious_activity',
      ip: ip,
      activity: activity,
      details: details,
      timestamp: Time.current.iso8601
    }

    @logger.warn(message.to_json)
  end

  def log_rate_limit_exceeded(ip:, endpoint:, limit:)
    message = {
      event: 'rate_limit_exceeded',
      ip: ip,
      endpoint: endpoint,
      limit: limit,
      timestamp: Time.current.iso8601
    }

    @logger.warn(message.to_json)
  end
end
