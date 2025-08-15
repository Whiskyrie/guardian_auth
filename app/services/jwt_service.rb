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
    Rails.logger.info "JWT token has expired"
    nil
  rescue JWT::InvalidSignature
    Rails.logger.warn "JWT token has invalid signature"
    nil
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def self.valid_token?(token)
    decode(token).present?
  end
end
