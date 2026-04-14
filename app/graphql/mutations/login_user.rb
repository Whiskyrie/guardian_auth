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

      if user&.authenticate(password)
        # Update last login timestamp
        user.track_login!

        # Generate JWT token
        token = JwtService.encode(
          user_id: user.id,
          role: user.primary_role
        )

        # Log successful login
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
        # Log failed login attempt with specific reason
        failure_reason = user ? 'invalid_password' : 'user_not_found'

        AuditLogger.log_login(
          user_id: user&.id,
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          success: false,
          user: user,
          failure_reason: failure_reason
        )

        # Generic error message to prevent user enumeration
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
