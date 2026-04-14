module Mutations
  class RequestPasswordReset < BaseMutation
    include RateLimitMutation

    description 'Request a password reset token for an email address'
    rate_limited 'requestPasswordReset'

    argument :email, String, required: true, description: "Email address to send reset token to"

    field :success, Boolean, null: false, description: 'Whether the request was processed'
    field :message, String, null: true, description: 'Result message'
    field :errors, [Types::UserErrorType], null: false, description: 'List of errors'

    def resolve(email:)
      email = email.to_s.downcase.strip

      if email.blank?
        return {
          success: false,
          message: 'Email is required',
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'Email is required')
        }
      end

      # Always return success to prevent user enumeration
      # Even if the email doesn't exist, we say "check your email"
      generic_success = {
        success: true,
        message: 'If an account with that email exists, a password reset token has been generated',
        errors: []
      }

      user = User.find_by(email: email)
      return generic_success unless user

      # Check if user is locked out from password resets
      # (Using a simple Redis-based check since we removed the DB columns)
      lock_key = "password_reset_lock:#{email}"
      if Rails.cache.read(lock_key)
        # Silently return success to avoid revealing lockout status
        return generic_success
      end

      # Rate limit: max 5 requests per hour per email
      rate_key = "password_reset_rate:#{email}"
      attempts = Rails.cache.read(rate_key).to_i
      if attempts >= PasswordResetToken::MAX_ATTEMPTS
        # Lock the account from further reset requests
        Rails.cache.write(lock_key, true, expires_in: PasswordResetToken::LOCKOUT_DURATION)
        return generic_success
      end

      # Generate reset token
      begin
        PasswordResetToken.create_for_user(
          user,
          ip_address: context[:remote_ip],
          user_agent: context[:user_agent]
        )

        # Increment rate limit counter
        Rails.cache.write(rate_key, attempts + 1, expires_in: 1.hour)

        # Audit log
        AuditLogger.log(
          action: 'password_reset_requested',
          resource: 'User',
          resource_id: user.id.to_s,
          user_id: user.id,
          metadata: {
            ip_address: context[:remote_ip],
            user_agent: context[:user_agent],
            activity: 'password_reset_request'
          },
          result: 'success'
        )

        # TODO: Send email with the raw_token
        # For now, the token is only available via the API response in development
        # In production, this would be sent via email and NOT returned in the response
        Rails.logger.info "Password reset token generated for user #{user.id}" if Rails.env.development?
      rescue StandardError => e
        Rails.logger.error "RequestPasswordReset error: #{e.class}: #{e.message}"
        # Still return generic success to prevent enumeration
      end

      generic_success
    end
  end
end
