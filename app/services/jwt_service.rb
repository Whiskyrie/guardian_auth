class JwtService
  ALGORITHM = 'HS256'.freeze

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:iat] = Time.current.to_i
    payload[:jti] = SecureRandom.uuid
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })[0]
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

  def self.decode_allowing_expired(token)
    body = JWT.decode(token, secret_key, true, {
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
    Rails.logger.info "Token #{jti} already blacklisted"
    true
  end

  def self.blacklist_user_tokens!(user_id, reason: 'password_change')
    user = User.find(user_id)
    user.update!(tokens_valid_after: Time.current)
  end

  def self.extract_jti_from_token(token)
    decoded = decode_allowing_expired(token)
    decoded&.dig('jti')
  end

  class << self
    private

    def secret_key
      @secret_key ||= Rails.application.credentials.secret_key_base ||
                      raise(ArgumentError, 'Missing secret_key_base in credentials')
    end
  end
end
