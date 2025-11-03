class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:iat] = Time.current.to_i
    payload[:jti] = SecureRandom.uuid
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature
    Rails.logger.info 'JWT token has expired'
    nil
  rescue JWT::InvalidSignature
    Rails.logger.warn 'JWT token has invalid signature'
    nil
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def self.decode_allowing_expired(token)
    # First try to decode normally
    decoded = decode(token)
    return decoded if decoded

    # If failed due to expiration, try to decode without verification
    begin
      body = JWT.decode(token, SECRET_KEY, false)[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::InvalidSignature
      Rails.logger.warn 'JWT token has invalid signature'
      nil
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWT decode error: #{e.message}"
      nil
    end
  end

  def self.valid_token?(token)
    return false unless decode(token).present?

    # Check if token is blacklisted
    decoded = decode(token)
    jti = decoded&.dig('jti')
    return false if jti && blacklisted?(jti)

    true
  end

  def self.blacklisted?(jti)
    TokenBlacklist.blacklisted?(jti)
  end

  def self.blacklist_token!(token, user_id, reason: 'logout')
    decoded = decode_without_verification(token)
    return false unless decoded

    jti = decoded['jti']
    exp = decoded['exp']
    expires_at = exp ? Time.at(exp) : 24.hours.from_now

    TokenBlacklist.create!(
      jti: jti,
      user_id: user_id,
      expires_at: expires_at,
      reason: reason
    )
  rescue ActiveRecord::RecordNotUnique
    # Token already blacklisted
    Rails.logger.info "Token #{jti} already blacklisted"
    true
  end

  def self.blacklist_user_tokens!(user_id, reason: 'password_change')
    # For mass invalidation, we'll use a different approach
    # Update user's tokens_valid_after timestamp
    user = User.find(user_id)
    user.update!(tokens_valid_after: Time.current)
  end

  def self.extract_jti_from_token(token)
    decoded = decode_without_verification(token)
    decoded&.dig('jti')
  end

  def self.decode_without_verification(token)
    body = JWT.decode(token, nil, false)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

end
