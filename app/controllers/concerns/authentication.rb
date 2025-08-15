# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  private

  def current_user_from_token
    return nil unless authorization_header.present?

    token = extract_token_from_header
    return nil unless token

    decoded_token = JwtService.decode(token)
    return nil unless decoded_token

    user_id = decoded_token['user_id']
    return nil unless user_id

    User.find_by(id: user_id)
  rescue StandardError => e
    Rails.logger.warn "Authentication error: #{e.message}"
    nil
  end

  def authorization_header
    request.headers['Authorization']
  end

  def extract_token_from_header
    return nil unless authorization_header

    # Expected format: "Bearer <token>"
    token_match = authorization_header.match(/^Bearer\s+(.+)$/i)
    token_match&.[](1)
  end

  def authenticate_user!
    current_user_from_token || raise_authentication_error
  end

  def raise_authentication_error
    raise GraphQL::ExecutionError, 'Authentication required. Please provide a valid token.'
  end
end
