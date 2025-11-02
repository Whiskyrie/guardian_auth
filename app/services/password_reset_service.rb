# frozen_string_literal: true

# PasswordResetService for managing password reset requests and validation
# Handles secure token generation, rate limiting, and password updates
class PasswordResetService
  include AuditLogger

  # Constants
  MAX_ATTEMPTS_PER_HOUR = 3
  TOKEN_EXPIRATION_HOURS = 1
  LOCKOUT_DURATION_HOURS = 1

  class << self
    # Request password reset for an email
    # Always returns success: true to prevent user enumeration
    def request_reset(email:, ip_address:, user_agent:)
      user = User.find_by(email: email.downcase.strip)

      # frozen_string_literal: true

# PasswordResetService for managing password reset requests and validation
# Handles secure token generation, rate limiting, and password updates
class PasswordResetService
  include AuditLogger

  # Constants
  MAX_ATTEMPTS_PER_HOUR = 3
  TOKEN_EXPIRATION_HOURS = 1
  LOCKOUT_DURATION_HOURS = 1

  class << self
    # Request password reset for an email
    # Always returns success: true to prevent user enumeration
    def request_reset(email:, ip_address:, user_agent:)
      user = User.find_by(email: email.downcase.strip)
      
      # Always return success to prevent email enumeration
      return success_response unless user

      # Check rate limiting
      rate_limit_check = check_rate_limit(user)
      return rate_limit_check unless rate_limit_check[:allowed]

      # Process reset request for existing user
      process_reset_request(user, ip_address, user_agent)
    rescue => e
      handle_request_error(email, ip_address, e)
    end

    # Validate a reset token
    def validate_token(token:)
      return invalid_token_response('Token é obrigatório') if token.blank?

      reset_token = PasswordResetToken.find_valid_token(token)
      
      if reset_token
        {
          valid: true,
          error: nil,
          user: reset_token.user,
          expires_at: reset_token.expires_at,
          time_remaining: reset_token.time_remaining
        }
      else
        {
          valid: false,
          error: 'Token inválido ou expirado',
          user: nil,
          expires_at: nil
        }
      end
    rescue => e
      Rails.logger.error "Token validation error: #{e.message}"
      {
        valid: false,
        error: 'Erro interno ao validar token',
        user: nil,
        expires_at: nil
      }
    end

    # Reset password using token
    def reset_password(token:, new_password:, confirm_password:)
      # Validate inputs
      return invalid_input_response if token.blank? || new_password.blank? || confirm_password.blank?

      # Validate token
      token_validation = validate_token(token: token)
      return token_validation unless token_validation[:valid]

      user = token_validation[:user]

      # Validate password confirmation
      if new_password != confirm_password
        return {
          success: false,
          errors: ['Senha e confirmação não coincidem'],
          user: nil
        }
      end

      # Validate password strength
      password_validation = validate_password_strength(new_password)
      return password_validation unless password_validation[:valid]

      # Use the reset token and update password
      execute_password_reset(user, token, new_password)
    rescue => e
      handle_reset_error(token, e)
    end

    # Check if user is rate limited
    def check_rate_limit(user)
      # Check if user is locked out
      if user.password_reset_locked_until && user.password_reset_locked_until > Time.current
        remaining_time = ((user.password_reset_locked_until - Time.current) / 60).ceil
        return {
          allowed: false,
          error: "Muitas tentativas. Tente novamente em #{remaining_time} minutos.",
          remaining: 0,
          reset_at: user.password_reset_locked_until
        }
      end

      # Check attempt count in last hour
      recent_attempts = user.password_reset_tokens.recent(1).count
      
      if recent_attempts >= MAX_ATTEMPTS_PER_HOUR
        lockout_duration = calculate_lockout_duration(recent_attempts)
        
        user.update!(password_reset_locked_until: lockout_duration.from_now)
        
        SecurityLogger.log_suspicious_activity(
          user_id: user.id,
          activity: 'password_reset_rate_limited',
          details: { attempts: recent_attempts, lockout_duration: lockout_duration }
        )
        
        return {
          allowed: false,
          error: "Muitas tentativas. Tente novamente em #{(lockout_duration / 60).ceil} minutos.",
          remaining: 0,
          reset_at: user.password_reset_locked_until
        }
      end

      {
        allowed: true,
        remaining: MAX_ATTEMPTS_PER_HOUR - recent_attempts,
        reset_at: 1.hour.from_now
      }
    end

    private

    def success_response
      {
        success: true,
        message: 'Se o email existir, você receberá instruções para resetar sua senha.',
        expires_in_hours: TOKEN_EXPIRATION_HOURS
      }
    end

    def invalid_token_response(error_message)
      {
        valid: false,
        error: error_message,
        user: nil,
        expires_at: nil
      }
    end

    def invalid_input_response
      {
        success: false,
        errors: ['Token, nova senha e confirmação são obrigatórios'],
        user: nil
      }
    end

    def process_reset_request(user, ip_address, user_agent)
      # Invalidate existing active tokens for this user
      invalidate_existing_tokens(user)

      # Generate new token
      token_data = TokenGenerator.generate_reset_token
      
      # Create password reset token record
      user.password_reset_tokens.create!(
        token_hash: token_data[:hash],
        expires_at: TOKEN_EXPIRATION_HOURS.hours.from_now,
        ip_address: ip_address,
        user_agent: user_agent
      )

      # Update user tracking fields
      user.update!(
        password_reset_attempts: user.password_reset_attempts + 1,
        last_password_reset_at: Time.current
      )

      # Log the attempt
      log_password_reset_request(user, ip_address, user_agent)

      # Queue email sending job
      SendPasswordResetEmailJob.perform_later(user.id, token_data[:token])

      success_response
    end

    def execute_password_reset(user, token, new_password)
      # Use the reset token
      reset_token = PasswordResetToken.find_valid_token(token)
      reset_token.use!

      # Update user password
      if user.update(password: new_password)
        # Invalidate all user sessions (logout from all devices)
        invalidate_all_user_sessions(user)
        
        # Update tokens_valid_after to invalidate existing JWTs
        user.update!(tokens_valid_after: Time.current)

        # Log successful password reset
        log_password_reset_success(user)

        {
          success: true,
          errors: [],
          user: user
        }
      else
        {
          success: false,
          errors: user.errors.full_messages,
          user: nil
        }
      end
    end

    def calculate_lockout_duration(recent_attempts)
      case recent_attempts
      when 3..5 then 1.hour
      when 6..10 then 3.hours
      else 24.hours
      end
    end

    def handle_request_error(email, ip_address, error)
      Rails.logger.error "Password reset request error: #{error.message}"
      SecurityLogger.log_suspicious_activity(
        ip: ip_address,
        activity: 'password_reset_request_error',
        details: { email: email, error: error.message }
      )
      
      success_response # Always return success
    end

    def handle_reset_error(token, error)
      Rails.logger.error "Password reset error: #{error.message}"
      SecurityLogger.log_suspicious_activity(
        activity: 'password_reset_error',
        details: { error: error.message, token_present: token.present? }
      )
      
      {
        success: false,
        errors: ['Erro interno ao resetar senha'],
        user: nil
      }
    end

    def invalidate_existing_tokens(user)
      user.password_reset_tokens.active.unused.update_all(used: true, used_at: Time.current)
    end

    def invalidate_all_user_sessions(user)
      SecurityLogger.log_security_event(
        user_id: user.id,
        event: 'password_reset_sessions_invalidated',
        details: { reason: 'password_reset' }
      )
    end

    def validate_password_strength(password)
      temp_user = User.new(password: password)
      
      if temp_user.valid?
        { valid: true, errors: [] }
      else
        {
          valid: false,
          errors: temp_user.errors[:password]
        }
      end
    end

    def log_password_reset_request(user, ip_address, user_agent)
      log_audit(
        user: user,
        action: 'password_reset_requested',
        resource: 'User',
        resource_id: user.id.to_s,
        result: 'success',
        metadata: {
          ip_address: ip_address,
          user_agent: user_agent,
          email: user.email
        }
      )
    end

    def log_password_reset_success(user)
      log_audit(
        user: user,
        action: 'password_reset_completed',
        resource: 'User',
        resource_id: user.id.to_s,
        result: 'success',
        metadata: {
          email: user.email,
          timestamp: Time.current.iso8601
        }
      )
    end
  end
end

      # Check rate limiting
      rate_limit_check = check_rate_limit(user)
      return rate_limit_check unless rate_limit_check[:allowed]

      # Invalidate existing active tokens for this user
      invalidate_existing_tokens(user)

      # Generate new token
      token_data = TokenGenerator.generate_reset_token

      # Create password reset token record
      user.password_reset_tokens.create!(
        token_hash: token_data[:hash],
        expires_at: TOKEN_EXPIRATION_HOURS.hours.from_now,
        ip_address: ip_address,
        user_agent: user_agent
      )

      # Update user tracking fields
      user.update!(
        password_reset_attempts: user.password_reset_attempts + 1,
        last_password_reset_at: Time.current
      )

      # Log the attempt
      log_password_reset_request(user, ip_address, user_agent)

      # Queue email sending job
      SendPasswordResetEmailJob.perform_later(user.id, token_data[:token])

      {
        success: true,
        message: 'Se o email existir, você receberá instruções para resetar sua senha.',
        expires_in_hours: TOKEN_EXPIRATION_HOURS
      }
    rescue StandardError => e
      Rails.logger.error "Password reset request error: #{e.message}"
      SecurityLogger.log_suspicious_activity(
        ip: ip_address,
        activity: 'password_reset_request_error',
        details: { email: email, error: e.message }
      )

      {
        success: true, # Always return success
        message: 'Se o email existir, você receberá instruções para resetar sua senha.'
      }
    end

    # Validate a reset token
    def validate_token(token:)
      return { valid: false, error: 'Token é obrigatório' } if token.blank?

      reset_token = PasswordResetToken.find_valid_token(token)

      unless reset_token
        return {
          valid: false,
          error: 'Token inválido ou expirado',
          user: nil,
          expires_at: nil
        }
      end

      {
        valid: true,
        error: nil,
        user: reset_token.user,
        expires_at: reset_token.expires_at,
        time_remaining: reset_token.time_remaining
      }
    rescue StandardError => e
      Rails.logger.error "Token validation error: #{e.message}"
      {
        valid: false,
        error: 'Erro interno ao validar token',
        user: nil,
        expires_at: nil
      }
    end

    # Reset password using token
    def reset_password(token:, new_password:, confirm_password:)
      # Validate token
      token_validation = validate_token(token: token)
      return token_validation unless token_validation[:valid]

      user = token_validation[:user]

      # Validate password confirmation
      if new_password != confirm_password
        return {
          success: false,
          errors: ['Senha e confirmação não coincidem'],
          user: nil
        }
      end

      # Validate password strength
      password_validation = validate_password_strength(new_password)
      return password_validation unless password_validation[:valid]

      # Use the reset token
      reset_token = PasswordResetToken.find_valid_token(token)
      reset_token.use!

      # Update user password
      if user.update(password: new_password)
        # Invalidate all user sessions (logout from all devices)
        invalidate_all_user_sessions(user)

        # Update tokens_valid_after to invalidate existing JWTs
        user.update!(tokens_valid_after: Time.current)

        # Log successful password reset
        log_password_reset_success(user)

        {
          success: true,
          errors: [],
          user: user
        }
      else
        {
          success: false,
          errors: user.errors.full_messages,
          user: nil
        }
      end
    rescue StandardError => e
      Rails.logger.error "Password reset error: #{e.message}"
      SecurityLogger.log_suspicious_activity(
        activity: 'password_reset_error',
        details: { error: e.message, token_present: token.present? }
      )

      {
        success: false,
        errors: ['Erro interno ao resetar senha'],
        user: nil
      }
    end

    # Check if user is rate limited
    def check_rate_limit(user)
      # Check if user is locked out
      if user.password_reset_locked_until && user.password_reset_locked_until > Time.current
        remaining_time = ((user.password_reset_locked_until - Time.current) / 60).ceil
        return {
          allowed: false,
          error: "Muitas tentativas. Tente novamente em #{remaining_time} minutos.",
          remaining: 0,
          reset_at: user.password_reset_locked_until
        }
      end

      # Check attempt count in last hour
      recent_attempts = user.password_reset_tokens.recent(1).count

      if recent_attempts >= MAX_ATTEMPTS_PER_HOUR
        # Lock user for increasing durations based on attempt count
        lockout_duration = case recent_attempts
                           when 3..5 then 1.hour
                           when 6..10 then 3.hours
                           else 24.hours
                           end

        user.update!(password_reset_locked_until: lockout_duration.from_now)

        SecurityLogger.log_suspicious_activity(
          user_id: user.id,
          activity: 'password_reset_rate_limited',
          details: { attempts: recent_attempts, lockout_duration: lockout_duration }
        )

        return {
          allowed: false,
          error: "Muitas tentativas. Tente novamente em #{(lockout_duration / 60).ceil} minutos.",
          remaining: 0,
          reset_at: user.password_reset_locked_until
        }
      end

      {
        allowed: true,
        remaining: MAX_ATTEMPTS_PER_HOUR - recent_attempts,
        reset_at: 1.hour.from_now
      }
    end

    private

    def invalidate_existing_tokens(user)
      user.password_reset_tokens.active.unused.update_all(used: true, used_at: Time.current)
    end

    def invalidate_all_user_sessions(user)
      # Add all current user tokens to blacklist
      # This will be implemented when we have access to the JWT service
      SecurityLogger.log_security_event(
        user_id: user.id,
        event: 'password_reset_sessions_invalidated',
        details: { reason: 'password_reset' }
      )
    end

    def validate_password_strength(password)
      # Use existing User model validations
      temp_user = User.new(password: password)

      unless temp_user.valid?
        errors = temp_user.errors[:password]
        return {
          valid: false,
          errors: errors
        }
      end

      { valid: true, errors: [] }
    end

    def log_password_reset_request(user, ip_address, user_agent)
      log_audit(
        user: user,
        action: 'password_reset_requested',
        resource: 'User',
        resource_id: user.id.to_s,
        result: 'success',
        metadata: {
          ip_address: ip_address,
          user_agent: user_agent,
          email: user.email
        }
      )
    end

    def log_password_reset_success(user)
      log_audit(
        user: user,
        action: 'password_reset_completed',
        resource: 'User',
        resource_id: user.id.to_s,
        result: 'success',
        metadata: {
          email: user.email,
          timestamp: Time.current.iso8601
        }
      )
    end
  end
end
