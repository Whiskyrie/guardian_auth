class Session < ApplicationRecord
  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active,   -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }
  scope :revoked,  -> { where.not(revoked_at: nil) }
  scope :expired,  -> { where('expires_at <= ?', Time.current) }

  def self.issue!(user:, ip:, user_agent:, role: nil)
    issued = JwtService.issue({ user_id: user.id, role: role || user.primary_role })
    session = create!(
      user: user,
      jti: issued.jti,
      expires_at: issued.expires_at,
      ip_address: ip,
      user_agent: user_agent&.first(512)
    )
    [issued.token, session]
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!(reason: 'user_revoked')
    return false if revoked?

    transaction do
      update_columns(revoked_at: Time.current, revoked_reason: reason)
      TokenBlacklist.find_or_create_by!(jti: jti) do |bl|
        bl.user_id = user_id
        bl.expires_at = expires_at
        bl.reason = blacklist_reason_for(reason)
      end
    end
    true
  end

  private

  def blacklist_reason_for(reason)
    mapping = {
      'logout'             => 'logout',
      'user_revoked'       => 'logout',
      'admin_revoked'      => 'admin_logout',
      'token_refresh'      => 'token_refresh',
      'logout_all_devices' => 'admin_logout',
      'password_change'    => 'password_change',
      'security_breach'    => 'security_breach'
    }
    mapping.fetch(reason, 'logout')
  end
end
