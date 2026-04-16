module Mutations
  class ResetPassword < BaseMutation
    include RateLimitMutation

    description 'Reset password using a valid reset token'
    rate_limited 'resetPassword'

    argument :token, String, required: true, description: 'Password reset token'
    argument :new_password, String, required: true,
                                    description: 'Min 8 chars, must include ' \
                                                 'uppercase, lowercase, digit, and special char'

    field :success, Boolean, null: false, description: 'Whether the password was reset successfully'
    field :message, String, null: true, description: 'Result message'
    field :errors, [Types::UserErrorType], null: false, description: 'List of errors'

    def resolve(token:, new_password:)
      if token.blank?
        return {
          success: false,
          message: 'Reset token is required',
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'Reset token is required')
        }
      end

      if new_password.blank?
        return {
          success: false,
          message: 'New password is required',
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'New password is required')
        }
      end

      # Verify the token
      reset_token = PasswordResetToken.verify_token(token)

      unless reset_token
        return {
          success: false,
          message: 'Invalid or expired reset token',
          errors: auth_error(Errors::ErrorCodes::PASSWORD_RESET_TOKEN_INVALID, 'Invalid or expired reset token')
        }
      end

      user = reset_token.user

      unless user
        return {
          success: false,
          message: 'User not found',
          errors: auth_error(Errors::ErrorCodes::USER_NOT_FOUND, 'User not found')
        }
      end

      # Update password
      user.password = new_password
      user.password_confirmation = new_password

      if user.save
        # Mark token as used
        reset_token.mark_used!

        # Invalidate all existing JWT tokens for security
        user.update!(tokens_valid_after: Time.current)

        # Clear rate limit counters
        Rails.cache.delete("password_reset_rate:#{user.email}")
        Rails.cache.delete("password_reset_lock:#{user.email}")

        # Audit log
        AuditLogger.log(
          action: 'password_reset_completed',
          resource: 'User',
          resource_id: user.id.to_s,
          user: user,
          metadata: {
            ip_address: context[:remote_ip],
            user_agent: context[:user_agent],
            activity: 'password_reset'
          },
          result: 'success'
        )

        {
          success: true,
          message: 'Password has been reset successfully. Please login with your new password.',
          errors: []
        }
      else
        {
          success: false,
          message: 'Password reset failed',
          errors: format_model_errors(user)
        }
      end
    rescue StandardError => e
      Rails.logger.error "ResetPassword error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Password reset failed. Please try again.',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Password reset failed. Please try again.')
      }
    end
  end
end
