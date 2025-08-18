class TokenBlacklist < ApplicationRecord
  belongs_to :user

  # Constants
  VALID_REASONS = %w[logout password_change security_breach admin_logout].freeze

  # Validations
  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :reason, inclusion: { in: VALID_REASONS }

  # Scopes
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :active, -> { where('expires_at >= ?', Time.current) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_reason, ->(reason) { where(reason: reason) }

  # Class methods
  def self.blacklisted?(jti)
    active.exists?(jti: jti)
  end

  def self.cleanup_expired!
    deleted_count = expired.delete_all
    Rails.logger.info "Cleaned up #{deleted_count} expired tokens from blacklist"
    deleted_count
  end

  # Instance methods
  def expired?
    expires_at < Time.current
  end

  def active?
    !expired?
  end

  def logout_reason?
    reason == 'logout'
  end

  def security_reason?
    %w[password_change security_breach admin_logout].include?(reason)
  end
end