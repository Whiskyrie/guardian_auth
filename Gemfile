source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.1'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Authentication & Authorization
gem 'bcrypt', '~> 3.1.7'
gem 'jwt'
gem 'pundit'

# Security & Rate Limiting
gem 'rack-attack'

# Redis & Performance
gem 'connection_pool'
gem 'hiredis-client'
gem 'redis', '~> 5.0'

# Formatador
gem 'rubocop'
gem 'ruby-lsp'

# GraphQL
gem 'graphql'
gem 'graphql-batch'

# API Configuration
gem 'rack-cors'

# Environment Configuration
gem 'dotenv-rails'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem 'brakeman', require: false
  gem 'debug', platforms: [:mri, :windows], require: 'debug/prelude'
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'graphiql-rails'
  gem 'pry-rails'
end
