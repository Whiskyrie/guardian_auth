class User < ApplicationRecord
  include Auditable
  has_secure_password

  # Override password= to prevent clearing password_digest when nil
  # This allows updating user attributes without re-validating password
  def password=(unencrypted_password)
    if unencrypted_password.nil?
      @password = nil
    else
      super
    end
  end

  # Constants
  EMAIL_REGEX = /\A[a-zA-Z0-9][\w+\-.]*@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  VERIFICATION_TOKEN_EXPIRY = 24.hours
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes

  # Strong password requirements: min 8 chars, at least one uppercase, lowercase, digit, and special char
  PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}\z/

  # Common weak passwords to reject
  WEAK_PASSWORDS = %w[
    password 12345678 password123 admin123 qwerty123 letmein123
    welcome123 password1 123456789 qwertyuiop adminadmin useruser
  ].freeze

  # RBAC Associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :permissions, through: :roles
  has_many :granted_roles, class_name: 'UserRole', foreign_key: 'granted_by_id', dependent: :nullify
  has_many :password_reset_tokens, dependent: :destroy

  # Deactivation
  belongs_to :deactivated_by, class_name: 'User', optional: true
  has_many :deactivated_users, class_name: 'User', foreign_key: 'deactivated_by_id', dependent: :nullify, inverse_of: :deactivated_by

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: {
              with: EMAIL_REGEX,
              message: 'must be a valid email format'
            },
            length: { maximum: 255 }

  validates :password,
            length: { minimum: 8, maximum: 128 },
            format: {
              with: PASSWORD_REGEX,
              message: 'must be at least 8 characters, including at least ' \
                       'one uppercase letter, one lowercase letter, one digit, and one ' \
                       'special character (@$!%*?&)'
            },
            exclusion: {
              in: WEAK_PASSWORDS,
              message: 'is too common and easy to guess. Choose a more secure password.'
            },
            if: -> { new_record? || !password.nil? }

  validates :first_name, :last_name,
            presence: true,
            length: { minimum: 2, maximum: 50 },
            format: {
              with: /\A[a-zA-ZÀ-ÿ\s'-]+\z/,
              message: 'must contain only letters, spaces, hyphens, and apostrophes'
            }

  # Custom validation for password strength
  validate :password_not_similar_to_user_info, if: -> { password.present? }

  # Callbacks
  before_validation :normalize_email, on: %i[create update]
  after_create :assign_default_role
  before_save :sanitize_user_inputs

  # Scopes
  # Legacy scopes - converted to use RBAC
  scope :admins, -> { joins(:roles).where(roles: { name: 'admin' }) }
  scope :users, -> { joins(:roles).where(roles: { name: 'user' }) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where.not(last_login_at: nil) } # "has ever logged in" — unrelated to deactivation
  scope :inactive, -> { where(last_login_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :not_deactivated, -> { where(deactivated_at: nil) }

  # Role helper methods (maintaining compatibility)
  def admin?
    # Use new RBAC system only
    has_role?('admin')
  end

  def user?
    # Use new RBAC system only
    has_role?('user')
  end

  # RBAC Methods
  def has_role?(role_name)
    return false unless persisted?

    roles.exists?(name: role_name)
  end

  def has_permission?(resource, action)
    return false unless persisted?

    # Check through roles and permissions
    permissions.exists?(resource: resource, action: action)
  end

  def can?(permission_string, object = nil)
    return false unless persisted?

    resource, action = permission_string.split(':', 2)
    return false if resource.blank? || action.blank?

    # Handle self permissions
    case permission_string
    when 'users:read_own', 'users:update_own'
      return object == self if object.is_a?(User)
    when 'self:anyone'
      return true
    end

    # Check RBAC permissions
    has_permission?(resource, action)
  end

  def assign_role(role_name, granted_by: nil)
    role_obj = Role.find_by(name: role_name)
    return false unless role_obj

    user_roles.find_or_create_by(role: role_obj) do |ur|
      ur.granted_by = granted_by
      ur.granted_at = Time.current
    end

    true
  end

  def remove_role(role_name)
    user_roles.joins(:role).where(roles: { name: role_name }).destroy_all
  end

  def role_names
    roles.pluck(:name)
  end

  def permission_names
    permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" }
  end

  def primary_role
    # Return the highest privilege role
    return 'admin' if has_role?('admin')
    return 'user' if has_role?('user')

    role_names.first || 'user'
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.presence || email
  end

  # Authentication tracking
  def track_login!
    update!(last_login_at: Time.current)
  end

  def never_logged_in?
    last_login_at.nil?
  end

  def logged_in_recently?(time_frame = 24.hours)
    last_login_at.present? && last_login_at > time_frame.ago
  end

  # Profile update tracking
  def can_update_profile?
    admin? || profile_updated_at.nil? || profile_updated_at <= 7.days.ago
  end

  def track_profile_update!
    update_column(:profile_updated_at, Time.current)
  end

  # Account lockout
  def locked?
    locked_until.present? && locked_until > Time.current
  end

  def increment_failed_attempts!
    new_count = failed_login_attempts + 1
    attrs = { failed_login_attempts: new_count }
    attrs[:locked_until] = LOCKOUT_DURATION.from_now if new_count >= MAX_FAILED_ATTEMPTS
    update_columns(attrs)
    new_count >= MAX_FAILED_ATTEMPTS
  end

  def reset_failed_attempts!
    update_columns(failed_login_attempts: 0, locked_until: nil)
  end

  def lockout_remaining
    return 0 unless locked?

    ((locked_until - Time.current) / 60).ceil
  end

  # Email verification
  def email_verified?
    email_verified_at.present?
  end

  def generate_email_verification_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_columns(
      email_verification_digest: Digest::SHA256.hexdigest(raw_token),
      email_verification_sent_at: Time.current
    )
    raw_token
  end

  def verify_email!(token)
    digest = Digest::SHA256.hexdigest(token.to_s)
    return :invalid unless ActiveSupport::SecurityUtils.secure_compare(
      email_verification_digest.to_s, digest
    )
    return :expired if email_verification_sent_at.nil? ||
                       email_verification_sent_at < VERIFICATION_TOKEN_EXPIRY.ago
    return :already_verified if email_verified?

    update_columns(
      email_verified_at: Time.current,
      email_verification_digest: nil,
      email_verification_sent_at: nil
    )
    :ok
  end

  def verification_cooldown_active?
    email_verification_sent_at.present? &&
      email_verification_sent_at > 15.minutes.ago
  end

  # Status helpers
  def active?
    persisted? && !deactivated?
  end

  def deactivated?
    deactivated_at.present?
  end

  def deactivate!(by:, reason: nil)
    return false if deactivated?

    update_columns(
      deactivated_at: Time.current,
      deactivated_by_id: by&.id,
      deactivation_reason: reason,
      tokens_valid_after: Time.current
    )
    true
  end

  def activate!
    return false unless deactivated?

    update_columns(
      deactivated_at: nil,
      deactivated_by_id: nil,
      deactivation_reason: nil
    )
    true
  end

  # Class methods
  def self.find_by_email(email)
    find_by(email: email&.downcase&.strip)
  end

  def self.admins_count
    admins.count
  end

  def self.users_count
    users.count
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def assign_default_role
    # Assign default 'user' role if no roles are assigned
    return unless roles.empty?

    default_role = Role.find_or_create_by!(name: 'user') do |r|
      r.description = 'Default user role'
      r.system_role = true
    end
    user_roles.create!(role: default_role, granted_at: Time.current)
  end

  def sanitize_user_inputs
    # Remove potential XSS and injection attempts
    self.first_name = sanitize_input(first_name)
    self.last_name = sanitize_input(last_name)
    self.email = sanitize_email(email)
  end

  def sanitize_input(input)
    return nil if input.blank?

    # Remove HTML tags, scripts, and dangerous characters
    sanitized = input.to_s.strip
    sanitized = sanitized.gsub(%r{<script\b[^<]*(?:(?!</script>)<[^<]*)*</script>}mi, '')
    sanitized = sanitized.gsub(/<[^>]*>/, '')
    sanitized = sanitized.gsub(/[<>]/, '')
    sanitized = sanitized.squeeze(' ')

    sanitized
  end

  def sanitize_email(email)
    return nil if email.blank?

    # Basic email sanitization
    sanitized = email.to_s.downcase.strip
    sanitized = sanitized.gsub(/[<>]/, '')

    sanitized
  end

  def password_not_similar_to_user_info
    return unless password.present?

    # Check if password contains user information
    user_info = [first_name, last_name, email&.split('@')&.first].compact.map(&:downcase)
    password_downcase = password.downcase

    user_info.each do |info|
      next if info.length < 3

      if password_downcase.include?(info)
        errors.add(:password, 'must not contain personal information such as name or email')
        break
      end
    end
  end

  # Override audit methods for User model
  def audit_action_for(action)
    case action
    when :create then 'register'
    when :update then 'user_update'
    when :destroy then 'user_deletion'
    else action.to_s
    end
  end

  def should_audit?
    # Always audit user actions for security
    true
  end

  def audit_user
    # For user operations, try to get current user from thread
    # If no current user (like in tests), use self for updates/deletions
    Thread.current[:current_user] || (defined?(Current) && Current&.user) || (persisted? ? self : nil)
  end
end
