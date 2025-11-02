# frozen_string_literal: true

# PasswordResetToken model for managing password reset tokens
# Handles token validation, expiration, and cleanup
class PasswordResetToken < ApplicationRecord
  belongs_to :user

  # Constants
  TOKEN_EXPIRATION_HOURS = 1
  MAX_ATTEMPTS_PER_HOUR = 3

  # Validations
  validates :token_hash, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :active, -> { where('expires_at >= ?', Time.current) }
  scope :unused, -> { where(used: false) }
  scope :used, -> { where(used: true) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, ->(hours = 1) { where('created_at >= ?', hours.hours.ago) }

  # Class methods
  def self.valid?(token)
    return false unless token.present?

    token_hash = Digest::SHA256.hexdigest(token)
    active.unused.exists?(token_hash: token_hash)
  end

  def self.find_valid_token(token)
    return nil unless token.present?

    token_hash = Digest::SHA256.hexdigest(token)
    active.unused.find_by(token_hash: token_hash)
  end

  def self.cleanup_expired!
    deleted_count = expired.delete_all
    Rails.logger.info "Cleaned up #{deleted_count} expired password reset tokens"
    deleted_count
  end

  def self.attempt_count_for_email(email, hours = 1)
    User.joins(:password_reset_tokens)
        .where(email: email.downcase.strip)
        .where('password_reset_tokens.created_at >= ?', hours.hours.ago)
        .count
  end

  # Instance methods
  def expired?
    expires_at < Time.current
  end

  def active?
    !expired? && !used?
  end

  def valid?
    active?
  end

  def use!
    update!(used: true, used_at: Time.current)
  end

  def time_remaining
    return 0 if expired?

    ((expires_at - Time.current) / 60).ceil # minutes
  end

  def expired_in_words
    minutes = time_remaining
    if minutes > 60
      hours = (minutes / 60).ceil
      "#{hours} #{'hora'.pluralize(hours)}"
    else
      "#{minutes} #{'minuto'.pluralize(minutes)}"
    end
  end
end
