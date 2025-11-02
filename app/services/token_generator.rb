# frozen_string_literal: true

# TokenGenerator service for secure token generation and validation
# Provides cryptographically secure random tokens with SHA-256 hashing
class TokenGenerator
  TOKEN_LENGTH = 32 # 32 bytes for high entropy

  # Generates a secure reset token and its hash
  # Returns a hash with :token and :hash keys
  def self.generate_reset_token
    # Generate cryptographically secure random token
    raw_token = SecureRandom.urlsafe_base64(TOKEN_LENGTH)

    # Hash the token for secure storage
    token_hash = Digest::SHA256.hexdigest(raw_token)

    {
      token: raw_token,
      hash: token_hash
    }
  end

  # Validates if a token matches its hash
  def self.valid_token?(token, hash)
    return false if token.blank? || hash.blank?

    computed_hash = Digest::SHA256.hexdigest(token)
    SecureCompare.secure_compare(computed_hash, hash)
  rescue StandardError => e
    Rails.logger.error "Token validation error: #{e.message}"
    false
  end

  # Generates a secure random token for temporary use (like email verification)
  # Does not hash the token - use for short-lived operations only
  def self.generate_temporary_token(length: 20)
    SecureRandom.urlsafe_base64(length)
  rescue StandardError => e
    Rails.logger.error "Token generation error: #{e.message}"
    raise SecurityError, 'Failed to generate secure token'
  end

  # Validates token strength (entropy check)
  def self.secure_token?(token)
    return false if token.blank?

    # Check minimum length
    return false if token.length < 16

    # Check character diversity
    has_lower = token =~ /[a-z]/
    has_upper = token =~ /[A-Z]/
    has_digit = token =~ /[0-9]/
    has_special = token =~ /[^a-zA-Z0-9]/

    [has_lower, has_upper, has_digit, has_special].count(nil).to_i <= 2
  rescue StandardError => e
    Rails.logger.error "Token strength validation error: #{e.message}"
    false
  end

  # Custom error class for token-related errors
  class SecurityError < StandardError; end
end
