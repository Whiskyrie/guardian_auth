
  # Use dedicated Redis cache store for rate limiting
  cache.store = Rails.application.config.rate_limit_cache_store

  # Enable Retry-After header for better client behavior
  self.throttled_response_retry_after_header = true

  # Custom throttled response with security headers
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'Content-Type' => 'application/json',
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s,
      'Retry-After' => match_data[:period].to_s,
      'X-Content-Type-Options' => 'nosniff',
      'X-Frame-Options' => 'DENY',
      'X-XSS-Protection' => '1; mode=block'
    }

    body = {
      errors: [
        {
          message: 'Rate limit exceeded. Please try again later.',
          extensions: {
            code: 'RATE_LIMIT_EXCEEDED',
            remaining: 0,
            reset_at: (now + (match_data[:period] - now % match_data[:period])).to_i,
            limit: match_data[:limit],
            retry_after: match_data[:period]
          }
        }
      ]
    }.to_json

    [429, headers, [body]]
  end

  # Custom blocklisted response
  self.blocklisted_responder = lambda do |request|
    headers = {
      'Content-Type' => 'application/json',
      'X-Content-Type-Options' => 'nosniff',
      'X-Frame-Options' => 'DENY',
      'X-XSS-Protection' => '1; mode=block'
    }

    body = {
      errors: [
        {
          message: 'Access denied due to suspicious activity.',
          extensions: {
            code: 'ACCESS_DENIED'
          }
        }
      ]
    }.to_json

    [403, headers, [body]]
  end

  # Safelist localhost and common development IPs
  safelist('allow from localhost') do |req|
    ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Safelist authenticated admin users (if API key present)
  safelist('allow authenticated admins') do |req|
    # Extract user from JWT token
    auth_header = req.get_header('HTTP_AUTHORIZATION')
    if auth_header
      token = auth_header.match(/^Bearer\s+(.+)$/i)&.[](1)
      if token
        begin
          decoded_token = JwtService.decode(token)
          user_role = decoded_token&.dig('role')
          user_role == 'admin'
        rescue StandardError
          false
        end
      end
    end
  end

  # Block suspicious paths and common attack vectors
  blocklist('block suspicious requests') do |req|
    # Block requests to common vulnerable paths
    suspicious_paths = [
      '/wp-admin', '/wp-login', '/wordpress',
      '/admin', '/administrator', '/phpmyadmin',
      '/etc/passwd', '/.env', '/config.php',
      '/xmlrpc.php', '/wp-content'
    ]

    # Block requests with suspicious query strings
    suspicious_patterns = [
      /union.*select/i, /script.*alert/i, /javascript:/i,
      /vbscript:/i, /onload.*=/i, /onerror.*=/i
    ]

    path_match = suspicious_paths.any? { |path| req.path.include?(path) }
    query_match = suspicious_patterns.any? { |pattern| req.query_string.match?(pattern) }

    path_match || query_match
  end

  # Fail2Ban: Block IPs that make repeated bad requests
  blocklist('fail2ban bad requests') do |req|
    # Block after 3 bad requests in 10 minutes, ban for 1 hour
    Rack::Attack::Fail2Ban.filter("bad-requests-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      # Consider 4xx responses as bad requests (except 401, 404, 429)
      req.env['rack.attack.match_data'] &&
        req.env['rack.attack.match_data'][:status] &&
        [400, 403, 422].include?(req.env['rack.attack.match_data'][:status])
    end
  end

  # General request throttling by IP
  throttle('requests by ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets', '/health')
  end

  # GraphQL specific throttling
  throttle('graphql requests', limit: 60, period: 1.minute) do |req|
    req.ip if req.path == '/graphql' && req.post?
  end

  # Login attempts throttling with exponential backoff
  (1..5).each do |level|
    throttle("login attempts level #{level}", limit: (5 * level), period: (2**level).minutes) do |req|
      if req.path == '/graphql' && req.post?
        # Extract operation name from GraphQL request
        begin
          body = req.body.read
          req.body.rewind
          parsed_body = JSON.parse(body)
          operation_name = parsed_body.dig('query')&.match(/mutation\s+(\w+)/)&.[](1)
          operation_name ||= parsed_body['operationName']

          req.ip if %w[loginUser Login SignIn].include?(operation_name)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end

  # User-specific login throttling (after authentication)
  throttle('login attempts by email', limit: 10, period: 10.minutes) do |req|
    if req.path == '/graphql' && req.post?
      begin
        body = req.body.read
        req.body.rewind
        parsed_body = JSON.parse(body)
        operation_name = parsed_body.dig('query')&.match(/mutation\s+(\w+)/)&.[](1)
        operation_name ||= parsed_body['operationName']

        if %w[loginUser Login SignIn].include?(operation_name)
          email = parsed_body.dig('variables', 'email') ||
                  parsed_body.dig('variables', 'input', 'email')
          email&.downcase&.strip if email.present?
        end
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Allow2Ban: More lenient blocking for login scrapers
  blocklist('allow2ban login scrapers') do |req|
    # Allow requests until hitting limit, then block
    # After 20 failed logins in 5 minutes, block for 2 hours
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 5.minutes, bantime: 2.hours) do
      if req.path == '/graphql' && req.post?
        begin
          body = req.body.read
          req.body.rewind
          parsed_body = JSON.parse(body)
          operation_name = parsed_body.dig('query')&.match(/mutation\s+(\w+)/)&.[](1)
          operation_name ||= parsed_body['operationName']

          %w[loginUser Login SignIn].include?(operation_name)
        rescue JSON::ParserError
          false
        end
      end
    end
  end

  # Track special user agents for monitoring
  track('suspicious user agents') do |req|
    suspicious_agents = [
      /bot/i, /crawl/i, /spider/i, /scan/i,
      /curl/i, /wget/i, /python/i, /java/i
    ]

    user_agent = req.user_agent.to_s
    suspicious_agents.any? { |pattern| user_agent.match?(pattern) }
  end

  # Track password change attempts for security monitoring
  track('password changes', limit: 5, period: 1.hour) do |req|
    if req.path == '/graphql' && req.post?
      begin
        body = req.body.read
        req.body.rewind
        parsed_body = JSON.parse(body)
        operation_name = parsed_body.dig('query')&.match(/mutation\s+(\w+)/)&.[](1)
        operation_name ||= parsed_body['operationName']

        %w[changePassword ChangePassword UpdatePassword].include?(operation_name)
      rescue JSON::ParserError
        false
      end
    end
  end
end

# Subscribe to notifications for logging
ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |name, start, finish, instrumenter_id, payload|
  req = payload[:request]
  Rails.logger.warn "SECURITY: Rate limit exceeded - IP: #{req.ip}, Path: #{req.path}, User-Agent: #{req.user_agent}"
end

ActiveSupport::Notifications.subscribe('blocklist.rack_attack') do |name, start, finish, instrumenter_id, payload|
  req = payload[:request]
  Rails.logger.error "SECURITY: Blocked request - IP: #{req.ip}, Path: #{req.path}, Reason: #{req.env['rack.attack.matched']}"
end

ActiveSupport::Notifications.subscribe('track.rack_attack') do |name, start, finish, instrumenter_id, payload|
  req = payload[:request]
  if req.env['rack.attack.matched'] == 'suspicious user agents'
    Rails.logger.info "SECURITY: Suspicious user agent detected - IP: #{req.ip}, User-Agent: #{req.user_agent}"
  elsif req.env['rack.attack.matched'] == 'password changes'
    Rails.logger.info "SECURITY: Password change attempt tracked - IP: #{req.ip}"
  end
end
