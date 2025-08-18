# frozen_string_literal: true

# Rate limiting configuration for GraphQL mutations
Rails.application.configure do
  # Rate limit configuration for authentication mutations
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

  # Optional: IP whitelist for admin/testing purposes
  # config.rate_limit_whitelist = ['127.0.0.1', '::1'].freeze
end
