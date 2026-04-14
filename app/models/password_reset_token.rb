class PasswordResetToken < ApplicationRecord
  belongs_to :user

  # Token expires after 1 hour
  EXPIRY_TIME = 1.hour.freeze
  # Max reset attempts before lockout
  MAX_ATTEMPTS = 5
  # Lockout duration after too many attempts
  LOCKOUT_DURATION = 30.minutes.freeze

  validates :token_hash, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(used: false).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :unused, -> { where(used: false) }

  # Generate a new reset token for a user
  def self.create_for_user(user, ip_address: nil, user_agent: nil)
    # Generate a random token
    raw_token = SecureRandom.urlsafe_base64(32)

    # Hash it for storage
    token_hash = Digest::SHA256.hexdigest(raw_token)

    # Invalidate any previous active tokens for this user
    user.password_reset_tokens.active.update_all(used: true, used_at: Time.current)

    # Create new token
    create!(
      user: user,
      token_hash: token_hash,
      expires_at: EXPIRY_TIME.from_now,
      ip_address: ip_address&.truncate(45),
      user_agent: user_agent&.truncate(255)
    )

    # Return the raw token (only time it's visible)
    raw_token
  end

  # Verify a raw token and return the matching record
  def self.verify_token(raw_token)
    token_hash = Digest::SHA256.hexdigest(raw_token)
    active.find_by(token_hash: token_hash)
  end

  # Mark token as used
  def mark_used!
    update!(used: true, used_at: Time.current)
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !used? && !expired?
  end
end
