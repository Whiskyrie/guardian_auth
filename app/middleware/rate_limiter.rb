# frozen_string_literal: true

class RateLimiter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Only apply rate limiting to GraphQL endpoint
    if request.path == '/graphql' && request.post?
      apply_rate_limiting(request, env)
    else
      @app.call(env)
    end
  end

  private

  def apply_rate_limiting(request, env)
    # Parse GraphQL query to get operation name
    operation_name = extract_operation_name(request)
    
    # Check if this operation should be rate limited
    if should_rate_limit?(operation_name)
      rate_limit_config = Rails.application.config.rate_limits[operation_name]
      identifier = get_identifier(request, rate_limit_config[:identifier])
      
      # Check rate limit
      result = RateLimitService.check_and_increment(
        operation: operation_name,
        identifier: identifier,
        limit: rate_limit_config[:limit],
        window: rate_limit_config[:window]
      )
      
      # Log rate limit attempts
      log_rate_limit_attempt(operation_name, identifier, result)
      
      # If rate limited, return error response with headers
      unless result[:allowed]
        return rate_limit_response(result)
      end
      
      # If allowed, continue with headers
      status, headers, body = @app.call(env)
      add_rate_limit_headers(headers, result)
      [status, headers, body]
    else
      @app.call(env)
    end
  end

  def extract_operation_name(request)
    body = request.body.read
    request.body.rewind
    
    begin
      parsed_body = JSON.parse(body)
      operation_name = parsed_body.dig('query')&.match(/mutation\s+(\w+)/)&.[](1)
      operation_name ||= parsed_body['operationName']
      operation_name
    rescue JSON::ParserError
      nil
    end
  end

  def should_rate_limit?(operation_name)
    operation_name && Rails.application.config.rate_limits.key?(operation_name)
  end

  def get_identifier(request, identifier_type)
    case identifier_type
    when :ip_address
      request.ip
    when :user_id
      # For user-based rate limiting, we need to extract user from token
      # This is a simplified version - in practice you might want to 
      # extract this from the Authorization header
      extract_user_id_from_request(request)
    else
      request.ip
    end
  end

  def extract_user_id_from_request(request)
    auth_header = request.get_header('HTTP_AUTHORIZATION')
    return nil unless auth_header

    token = auth_header.match(/^Bearer\s+(.+)$/i)&.[](1)
    return nil unless token

    decoded_token = JwtService.decode(token)
    decoded_token&.dig('user_id')
  rescue StandardError
    nil
  end

  def log_rate_limit_attempt(operation_name, identifier, result)
    if result[:allowed]
      Rails.logger.info "Rate limit check passed for #{operation_name} - Identifier: #{identifier}, " \
                       "Remaining: #{result[:remaining]}/#{result[:limit]}"
    else
      Rails.logger.warn "Rate limit exceeded for #{operation_name} - Identifier: #{identifier}, " \
                       "Limit: #{result[:limit]}, Reset at: #{result[:reset_at]}"
    end
  end

  def rate_limit_response(result)
    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => result[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => result[:reset_at].to_i.to_s
    }

    body = {
      errors: [
        {
          message: 'Rate limit exceeded. Please try again later.',
          extensions: {
            code: 'RATE_LIMIT_EXCEEDED',
            remaining: 0,
            reset_at: result[:reset_at].to_i,
            limit: result[:limit]
          }
        }
      ]
    }.to_json

    [429, headers, [body]]
  end

  def add_rate_limit_headers(headers, result)
    headers['X-RateLimit-Limit'] = result[:limit].to_s
    headers['X-RateLimit-Remaining'] = result[:remaining].to_s
    headers['X-RateLimit-Reset'] = result[:reset_at].to_i.to_s
  end
end
