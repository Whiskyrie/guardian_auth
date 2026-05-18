module Mutations
  class RefreshToken < BaseMutation

    description 'Refresh an expired or soon-to-expire JWT token'

    argument :token, String, required: true, description: 'Current JWT token (can be expired)'

    field :success, Boolean, null: false, description: 'Whether the token refresh was successful'
    field :message, String, null: true, description: 'Result message'
    field :token, String, null: true, description: 'New JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Current user object'
    field :errors, [Types::UserErrorType], null: false, description: 'List of refresh errors'

    # Maximum time window for token refresh (7 days after expiration)
    MAX_REFRESH_WINDOW = 7.days.freeze

    def resolve(token:)
      # Step 1: Validate input
      return error_response('Token cannot be blank', code: Errors::ErrorCodes::INVALID_INPUT) if token.blank?

      # Step 2: Decode and verify signature (allows expired tokens)
      decoded_payload = JwtService.decode_allowing_expired(token)
      return error_response('Invalid token format or signature') unless decoded_payload

      # Step 3: Extract JTI and check blacklist BEFORE any further processing
      # SECURITY: This is critical - blacklisted tokens must not be usable for refresh
      jti = decoded_payload['jti']
      if jti && JwtService.blacklisted?(jti)
        Rails.logger.warn "RefreshToken: Attempted use of blacklisted token jti=#{jti}"
        return error_response('Token has been revoked')
      end

      # Step 5: Find user from token payload
      user_id = decoded_payload['user_id']
      return error_response('Invalid token: missing user information') unless user_id

      user = User.find_by(id: user_id)
      return error_response('User not found or inactive', code: Errors::ErrorCodes::RESOURCE_NOT_FOUND) unless user&.id

      # Step 6: SECURITY - Check tokens_valid_after for mass invalidation
      # This prevents use of tokens issued before password change or logout_all_devices
      token_iat = decoded_payload['iat']
      if user.tokens_valid_after && token_iat
        token_issued_at = Time.at(token_iat)
        if token_issued_at < user.tokens_valid_after
          Rails.logger.warn(
            "RefreshToken: Token issued before tokens_valid_after. " \
            "user_id=#{user.id}, iat=#{token_issued_at}, valid_after=#{user.tokens_valid_after}"
          )
          return error_response('Token has been invalidated. Please login again.', code: Errors::ErrorCodes::TOKEN_EXPIRED)
        end
      end

      # Step 7: Check if token is not too old (max 7 days expired)
      token_exp = decoded_payload['exp']
      return error_response('Invalid token: missing expiration') unless token_exp

      max_refresh_window = MAX_REFRESH_WINDOW.ago.to_i
      if token_exp < max_refresh_window
        Rails.logger.info "Token too old: exp=#{token_exp}, window=#{max_refresh_window}"
        return error_response('Token too old to refresh', code: Errors::ErrorCodes::TOKEN_EXPIRED)
      end

      # Step 8: SECURITY - Blacklist the old refresh token (one-time use)
      # This prevents token replay attacks where a stolen refresh token could be reused
      if jti
        begin
          JwtService.blacklist_token!(token, user.id, reason: 'token_refresh')
          Rails.logger.info "RefreshToken: Blacklisted used token jti=#{jti} for user_id=#{user.id}"
        rescue StandardError => e
          # Log but don't fail - the blacklist check above already verified it wasn't blacklisted
          Rails.logger.warn "RefreshToken: Failed to blacklist old token: #{e.message}"
        end
      end

      # Step 9: Generate new token
      new_token = JwtService.encode(user_id: user.id, role: user.primary_role)
      return error_response('Failed to generate new token', code: Errors::ErrorCodes::INTERNAL_ERROR) unless new_token

      # Update last login timestamp
      user.update_column(:last_login_at, Time.current)

      # Return success response
      {
        success: true,
        message: 'Token refreshed successfully',
        token: new_token,
        user: user,
        errors: []
      }
    rescue ActiveRecord::RecordNotFound
      error_response('User not found', code: Errors::ErrorCodes::RESOURCE_NOT_FOUND)
    rescue StandardError => e
      Rails.logger.error "RefreshToken mutation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      error_response('Token refresh failed. Please login again.', code: Errors::ErrorCodes::INTERNAL_ERROR)
    end

    private

    def error_response(message, code: Errors::ErrorCodes::INVALID_TOKEN)
      {
        success: false,
        message: message,
        token: nil,
        user: nil,
        errors: [Types::UserError.new(message: message, code: code, field: nil)]
      }
    end
  end
end
