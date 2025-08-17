class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
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
    decode(token).present?
  end
end
