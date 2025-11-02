# frozen_string_literal: true

module Mutations
  # RequestPasswordReset mutation for requesting password reset via email
  # Handles rate limiting and security logging
  class RequestPasswordReset < BaseMutation
    include RateLimitMutation

    description 'Request password reset for user account'
    rate_limited 'requestPasswordReset'

    argument :email, String, required: true, description: "User's email address"

    field :success, Boolean, null: false, description: 'Whether the request was successful'
    field :message, String, null: true, description: 'Success or error message'
    field :expires_in_hours, Integer, null: true, description: 'Token expiration time in hours'
    field :errors, [String], null: false, description: 'List of validation errors'

    def resolve(email:)
      # Normalize and sanitize email input
      email = email.to_s.downcase.strip

      # Basic input validation
      if email.blank?
        return {
          success: false,
          message: nil,
          expires_in_hours: nil,
          errors: ['Email é obrigatório']
        }
      end

      # Validate email format
      unless email =~ User::EMAIL_REGEX
        return {
          success: false,
          message: nil,
          expires_in_hours: nil,
          errors: ['Email deve ter um formato válido']
        }
      end

      # Get request metadata for security logging
      ip_address = context[:request]&.remote_ip
      user_agent = context[:request]&.user_agent

      # Process password reset request
      result = PasswordResetService.request_reset(
        email: email,
        ip_address: ip_address,
        user_agent: user_agent
      )

      {
        success: result[:success],
        message: result[:message],
        expires_in_hours: result[:expires_in_hours],
        errors: result[:success] ? [] : [result[:message] || 'Erro interno']
      }
    rescue StandardError => e
      Rails.logger.error "RequestPasswordReset mutation error: #{e.message}"

      # Log security event
      SecurityLogger.log_suspicious_activity(
        ip: context[:request]&.remote_ip,
        activity: 'password_reset_request_error',
        details: { email: email, error: e.message }
      )

      {
        success: false,
        message: nil,
        expires_in_hours: nil,
        errors: ['Erro interno ao processar solicitação']
      }
    end
  end
end
