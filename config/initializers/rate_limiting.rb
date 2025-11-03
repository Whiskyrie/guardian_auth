# DEPRECATED
# This file is kept for reference but functionality has been moved to Rack::Attack
# See config/initializers/rack_attack.rb for current rate limiting configuration

Rails.application.configure do
  # Legacy configuration - now handled by Rack::Attack
  # Keeping for migration reference
  config.rate_limits = {
    'loginUser' => {
      limit: 5,
      window: 1.minute,
      identifier: :ip_address
    },
    'registerUser' => {
      limit: 3,
      window: 1.minute,
      identifier: :ip_address
    },
    'changePassword' => {
      limit: 3,
      window: 5.minutes,
      identifier: :user_id
    }
  }.freeze

  # IP whitelist for admin/testing purposes
  config.rate_limit_whitelist = [
    '127.0.0.1',
    '::1',
    ENV['ADMIN_IP']
  ].compact.freeze
end
