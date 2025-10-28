# config application.rb

require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

# Require custom middleware
require_relative '../app/middleware/security_headers_middleware'

module GuardianAuth
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    # Middleware configuration
    config.autoload_paths << Rails.root.join('app', 'middleware')
    
    # Security headers middleware
    config.middleware.use SecurityHeadersMiddleware
    
    # Rack::Attack for rate limiting and security
    config.middleware.use Rack::Attack

    # CORS configuration (more restrictive for security)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins do |source, env|
          # Allow requests from same origin and specific domains in production
          if Rails.env.development?
            true
          else
            # Add your frontend domains here
            %w[
              https://yourapp.com
              https://www.yourapp.com
              https://app.yourapp.com
            ].include?(source)
          end
        end
        
        resource '*',
                 headers: :any,
                 methods: %i[get post put patch delete options head],
                 expose: %w[Authorization X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
                 max_age: 86400
      end
    end
  end
end
