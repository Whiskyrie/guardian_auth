module Mutations
  class LoginUser < BaseMutation
    include RateLimitMutation
    
    description 'Authenticate user and return access token'
    rate_limited 'loginUser'

    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true, description: "User's password"

    field :token, String, null: true, description: 'JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Authenticated user object'
    field :errors, [String], null: false, description: 'List of authentication errors'

    def resolve(email:, password:)
      # Normalize and sanitize email input
      email = email.to_s.downcase.strip
      
      # Basic input validation
      if email.blank? || password.blank?
        SecurityLogger.log_login_attempt(
          email: email,
          ip: context[:request]&.remote_ip,
          user_agent: context[:request]&.user_agent,
          success: false,
          failure_reason: 'empty_credentials'
        )
        
        return {
          token: nil,
          user: nil,
          errors: ['Email e senha são obrigatórios']
        }
      end

      user = User.find_by(email: email)

      if user&.authenticate(password)
        # Update last login timestamp
        user.track_login!
        
        # Generate JWT token
        token = JwtService.encode(
          user_id: user.id,
          role: user.role
        )
        
        # Log successful login
        AuditLogger.log_login(
          email: email,
          ip: context[:request]&.remote_ip,
          user_agent: context[:request]&.user_agent,
          success: true,
          user: user
        )
        
        {
          token: token,
          user: user,
          errors: []
        }
      else
        # Log failed login attempt with specific reason
        failure_reason = user ? 'invalid_password' : 'user_not_found'
        
        AuditLogger.log_login(
          email: email,
          ip: context[:request]&.remote_ip,
          user_agent: context[:request]&.user_agent,
          success: false,
          user: user,
          failure_reason: failure_reason
        )
        
        # Generic error message to prevent user enumeration
        {
          token: nil,
          user: nil,
          errors: ['Email ou senha inválidos!']
        }
      end
    rescue StandardError => e
      Rails.logger.error "LoginUser mutation error: #{e.message}"
      
      # Log security incident
      AuditLogger.log(
        action: 'login_error',
        resource: 'User',
        metadata: {
          ip_address: context[:request]&.remote_ip,
          user_agent: context[:request]&.user_agent,
          error: e.message,
          email: email,
          activity: 'login_mutation_error'
        },
        result: 'failure'
      )
      
      {
        token: nil,
        user: nil,
        errors: ['Falha na autenticação. Tente novamente.']
      }
    end
  end
end
