# config application.rb

require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module GuardianAuth
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    # CORS configuration

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
                 headers: :any,
                 methods: %i[get post put patch delete options head]
      end
    end
  end
end
