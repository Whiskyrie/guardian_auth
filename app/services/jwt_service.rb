class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
  ALGORITHM = 'HS256'.freeze

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:iat] = Time.current.to_i
    payload[:jti] = SecureRandom.uuid
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature
    Rails.logger.info 'JWT token has expired'
    nil
  rescue JWT::VerificationError
    Rails.logger.warn 'JWT token has invalid signature'
    nil
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def self.decode_without_verification(token)
    body = JWT.decode(token, nil, false)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode without verification error: #{e.message}"
    nil
  end

  def self.decode_allowing_expired(token)
    # Decode with signature verification but skip expiration check
    body = JWT.decode(token, SECRET_KEY, true, {
                        algorithm: ALGORITHM,
                        verify_expiration: false,
                        verify_not_before: true,
                        verify_iat: true,
                        verify_jti: true,
                        sub: nil
                      })[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::VerificationError
    Rails.logger.warn 'JWT token has invalid signature in decode_allowing_expired'
    nil
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error in decode_allowing_expired: #{e.message}"
    nil
  end

  # Decodes once, verifies signature + expiry, checks blacklist.
  # Returns the payload hash or nil if the token is invalid/revoked.
  def self.decode_and_verify(token)
    decoded = decode(token)
    return nil unless decoded

    jti = decoded['jti']
    return nil if jti && blacklisted?(jti)

    decoded
  end

  def self.valid_token?(token)
    decode_and_verify(token).present?
  end

  # Check if a token is blacklisted (works with expired tokens too)
  # Useful for refresh token validation where tokens may be expired
  def self.token_blacklisted?(token)
    decoded = decode_allowing_expired(token)
    return false unless decoded

    jti = decoded['jti']
    return false unless jti

    blacklisted?(jti)
  end

  def self.blacklisted?(jti)
    TokenBlacklist.blacklisted?(jti)
  end

  def self.blacklist_token!(token, user_id, reason: 'logout')
    decoded = decode_allowing_expired(token)
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
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
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
    decoded = decode_allowing_expired(token)
    decoded&.dig('jti')
  end
end
