# frozen_string_literal: true

module Mutations
  # ResetPassword mutation for resetting password using valid token
  # Validates token and updates user password securely
  class ResetPassword < BaseMutation
    include RateLimitMutation

    description 'Reset user password using valid token'
    rate_limited 'resetPassword'

    argument :token, String, required: true, description: 'Password reset token'
    argument :new_password, String, required: true, description: 'New password'
    argument :confirm_password, String, required: true, description: 'Password confirmation'

    field :success, Boolean, null: false, description: 'Whether the password reset was successful'
    field :user, Types::UserType, null: true, description: 'User object after successful reset'
    field :errors, [String], null: false, description: 'List of validation errors'

    def resolve(token:, new_password:, confirm_password:)
      # Basic input validation
      if token.blank? || new_password.blank? || confirm_password.blank?
        return {
          success: false,
          user: nil,
          errors: ['Token, nova senha e confirmação são obrigatórios']
        }
      end

      # Process password reset
      result = PasswordResetService.reset_password(
        token: token,
        new_password: new_password,
        confirm_password: confirm_password
      )

      {
        success: result[:success],
        user: result[:success] ? result[:user] : nil,
        errors: result[:errors] || []
      }
    rescue StandardError => e
      Rails.logger.error "ResetPassword mutation error: #{e.message}"

      # Log security event
      SecurityLogger.log_suspicious_activity(
        activity: 'password_reset_mutation_error',
        details: { token_present: token.present?, error: e.message }
      )

      {
        success: false,
        user: nil,
        errors: ['Erro interno ao redefinir senha']
      }
    end
  end
end
