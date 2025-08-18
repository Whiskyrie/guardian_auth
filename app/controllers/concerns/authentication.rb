# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  private

  def current_user_from_token
    return nil unless authorization_header.present?

    token = extract_token_from_header
    return nil unless token

    # Store token for later use (logout operations)
    @current_token = token
    Rails.logger.info "Token extracted and stored: #{token[0..20]}..." if token

    # Check if token is valid (includes blacklist check)
    return nil unless JwtService.valid_token?(token)

    decoded_token = JwtService.decode(token)
    return nil unless decoded_token

    user_id = decoded_token['user_id']
    return nil unless user_id

    # Check if user has tokens_valid_after set (for mass invalidation)
    user = User.find_by(id: user_id)
    return nil unless user

    if user.tokens_valid_after.present?
      token_issued_at = Time.at(decoded_token['iat']) if decoded_token['iat']
      return nil if token_issued_at && token_issued_at < user.tokens_valid_after
    end

    user
  rescue StandardError => e
    Rails.logger.warn "Authentication error: #{e.message}"
    nil
  end

  def current_token
    Rails.logger.info "Current token requested: #{@current_token ? 'present' : 'nil'}"
    @current_token
  end

  def authorization_header
    request.headers['Authorization']
  end

  def extract_token_from_header
    return nil unless authorization_header

    Rails.logger.info "Authorization header: #{authorization_header}"
    # Expected format: "Bearer <token>"
    token_match = authorization_header.match(/^Bearer\s+(.+)$/i)
    extracted_token = token_match&.[](1)
    Rails.logger.info "Extracted token: #{extracted_token ? 'present' : 'nil'}"
    extracted_token
  end

  def authenticate_user!
    current_user_from_token || raise_authentication_error
  end

  def raise_authentication_error
    raise GraphQL::ExecutionError, 'Authentication required. Please provide a valid token.'
  end
end
