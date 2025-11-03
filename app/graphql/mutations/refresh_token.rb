module Mutations
  class RefreshToken < GraphQL::Schema::Mutation
    include AuthorizationHelper

    description 'Refresh an expired or soon-to-expire JWT token'

    argument :token, String, required: true, description: 'Current JWT token (can be expired)'

    field :token, String, null: true, description: 'New JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Current user object'
    field :errors, [String], null: false, description: 'List of refresh errors'

    # Helper method to access current_user from context
    def current_user
      context[:current_user]
    end

    def resolve(token:)
      # Validate input
      return error_response(['Token cannot be blank']) if token.blank?

      # Try to decode token first (without any verification)
      begin
        # Decode without verification to get payload
        body = JWT.decode(token, nil, false)[0]
        decoded_payload = HashWithIndifferentAccess.new(body)
      rescue JWT::DecodeError => e
        Rails.logger.warn "JWT decode error: #{e.message}"
        return error_response(['Invalid token format'])
      end

      # Verify signature separately
      begin
        JWT.decode(token, JwtService::SECRET_KEY, true, { verify_exp: false })
      rescue JWT::ExpiredSignature
        # Allow expired tokens to pass for refresh window validation
        Rails.logger.info "Token is expired, checking refresh window"
      rescue JWT::VerificationError
        return error_response(['Invalid token format'])
      end

      # Find user from token payload
      user_id = decoded_payload['user_id']
      return error_response(['Invalid token: missing user information']) unless user_id

      user = User.find_by(id: user_id)
      return error_response(['User not found or inactive']) unless user&.id

      # Check if token is not too old (max 7 days expired)
      token_exp = decoded_payload['exp']
      return error_response(['Invalid token: missing expiration']) unless token_exp

      max_refresh_window = 7.days.ago.to_i
      if token_exp < max_refresh_window
        Rails.logger.info "Token too old: exp=#{token_exp}, window=#{max_refresh_window}"
        return error_response(['Token too old to refresh'])
      end

      # Generate new token
      new_token = JwtService.encode(user_id: user.id)
      return error_response(['Failed to generate new token']) unless new_token

      # Update last login timestamp
      user.update_column(:last_login_at, Time.current)

      # Return success response
      {
        token: new_token,
        user: user,
        errors: []
      }
    rescue ActiveRecord::RecordNotFound
      error_response(['User not found'])
    rescue StandardError => e
      Rails.logger.error "RefreshToken mutation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      error_response(['Token refresh failed. Please login again.'])
    end

    private

    def error_response(errors)
      {
        token: nil,
        user: nil,
        errors: Array(errors)
      }
    end
  end
end
