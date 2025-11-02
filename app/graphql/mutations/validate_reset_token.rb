# frozen_string_literal: true

module Mutations
  # ValidateResetToken mutation for validating reset tokens without using them
  # Provides token validation status and remaining time
  class ValidateResetToken < BaseMutation
    include RateLimitMutation

    description 'Validate password reset token without using it'
    rate_limited 'validateResetToken'

    argument :token, String, required: true, description: 'Password reset token to validate'

    field :valid, Boolean, null: false, description: 'Whether the token is valid'
    field :user, Types::UserType, null: true, description: 'User associated with the token'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true, description: 'Token expiration timestamp'
    field :time_remaining, Integer, null: true, description: 'Time remaining in minutes'
    field :error, String, null: true, description: 'Error message if token is invalid'
    field :errors, [String], null: false, description: 'List of validation errors'

    def resolve(token:)
      # Basic input validation
      if token.blank?
        return {
          valid: false,
          user: nil,
          expires_at: nil,
          time_remaining: nil,
          error: 'Token é obrigatório',
          errors: ['Token é obrigatório']
        }
      end

      # Validate token
      result = PasswordResetService.validate_token(token: token)

      {
        valid: result[:valid],
        user: result[:valid] ? result[:user] : nil,
        expires_at: result[:expires_at],
        time_remaining: result[:time_remaining],
        error: result[:error],
        errors: result[:valid] ? [] : [result[:error]]
      }
    rescue StandardError => e
      Rails.logger.error "ValidateResetToken mutation error: #{e.message}"

      # Log security event
      SecurityLogger.log_suspicious_activity(
        activity: 'token_validation_error',
        details: { token_present: token.present?, error: e.message }
      )

      {
        valid: false,
        user: nil,
        expires_at: nil,
        time_remaining: nil,
        error: 'Erro interno ao validar token',
        errors: ['Erro interno ao validar token']
      }
    end
  end
end
