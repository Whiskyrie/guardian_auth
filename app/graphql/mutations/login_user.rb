module Mutations
  class LoginUser < BaseMutation
    include RateLimitMutation

    description 'Authenticate user and return access token'
    rate_limited 'loginUser'

    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true, description: "User's password"

    field :success, Boolean, null: false, description: 'Whether the login was successful'
    field :message, String, null: true, description: 'Result message'
    field :token, String, null: true, description: 'JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Authenticated user object'
    field :errors, [Types::UserErrorType], null: false, description: 'List of authentication errors'

    def resolve(email:, password:)
      # Normalize and sanitize email input
      email = email.to_s.downcase.strip

      # Basic input validation
      if email.blank? || password.blank?
        SecurityLogger.log_login_attempt(
          user_id: nil,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: false,
          failure_reason: 'empty_credentials'
        )

        return {
          success: false,
          message: 'Email and password are required',
          token: nil,
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'Email and password are required')
        }
      end

      user = User.find_by(email: email)

      # Verifica bloqueio antes de qualquer tentativa de autenticação
      if user&.locked?
        AuditLogger.log_login(
          user_id: user.id,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: false,
          user: user,
          failure_reason: 'account_locked'
        )

        minutes = user.lockout_remaining
        return {
          success: false,
          message: "Conta bloqueada. Tente novamente em #{minutes} #{minutes == 1 ? 'minuto' : 'minutos'}.",
          token: nil,
          user: nil,
          errors: auth_error(Errors::ErrorCodes::ACCOUNT_LOCKED, 'Conta temporariamente bloqueada')
        }
      end

      if user&.deactivated?
        AuditLogger.log_login(
          user_id: user.id,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: false,
          user: user,
          failure_reason: 'account_deactivated'
        )

        return {
          success: false,
          message: 'Conta desativada. Entre em contato com o administrador.',
          token: nil,
          user: nil,
          errors: auth_error(Errors::ErrorCodes::ACCOUNT_DEACTIVATED, 'Account is deactivated')
        }
      end

      if user&.authenticate(password)
        user.reset_failed_attempts!
        user.track_login!

        token = JwtService.encode(
          user_id: user.id,
          role: user.primary_role
        )

        AuditLogger.log_login(
          user_id: user.id,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: true,
          user: user
        )

        {
          success: true,
          message: 'Login successful',
          token: token,
          user: user,
          errors: []
        }
      else
        failure_reason = user ? 'invalid_password' : 'user_not_found'

        if user
          just_locked = user.increment_failed_attempts!

          if just_locked
            AuditLogger.log(
              action: 'account_locked',
              resource: 'User',
              resource_id: user.id,
              user: user,
              metadata: {
                ip_address: context[:remote_ip],
                user_agent: context[:user_agent],
                failed_attempts: user.failed_login_attempts
              },
              result: 'blocked'
            )
          end
        end

        AuditLogger.log_login(
          user_id: user&.id,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: false,
          user: user,
          failure_reason: failure_reason
        )

        {
          success: false,
          message: 'Invalid credentials',
          token: nil,
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_CREDENTIALS, 'Invalid email or password')
        }
      end
    rescue StandardError => e
      Rails.logger.error "LoginUser mutation error: #{e.message}"

      # Log security incident
      AuditLogger.log(
        action: 'login_error',
        resource: 'User',
        metadata: {
          ip_address: context[:remote_ip],
          user_agent: context[:user_agent],
          error: e.message,
          activity: 'login_mutation_error'
        },
        result: 'failure'
      )

      {
        success: false,
        message: 'Authentication failed. Please try again.',
        token: nil,
        user: nil,
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Authentication failed. Please try again.')
      }
    end
  end
end
