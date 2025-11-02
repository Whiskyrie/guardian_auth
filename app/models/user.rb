class User < ApplicationRecord
  include Auditable
  has_secure_password

  # Constants
  # Legacy constant - keeping for backwards compatibility
  VALID_ROLES = %w[user admin].freeze
  EMAIL_REGEX = /\A[a-zA-Z0-9][\w+\-.]*@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i

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

  # Password Reset Associations
  has_many :password_reset_tokens, dependent: :destroy

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: {
              with: EMAIL_REGEX,
              message: 'deve ter um formato válido'
            },
            length: { maximum: 255 }

  validates :password,
            length: { minimum: 8, maximum: 128 },
            format: {
              with: PASSWORD_REGEX,
              message: 'deve conter pelo menos 8 caracteres, incluindo pelo menos uma letra maiúscula, uma minúscula, um número e um caractere especial (@$!%*?&)'
            },
            exclusion: {
              in: WEAK_PASSWORDS,
              message: 'é muito comum e fácil de adivinhar. Escolha uma senha mais segura.'
            },
            if: -> { new_record? || !password.nil? }

  validates :first_name, :last_name,
            presence: true,
            length: { minimum: 2, maximum: 50 },
            format: {
              with: /\A[a-zA-ZÀ-ÿ\s'-]+\z/,
              message: 'deve conter apenas letras, espaços, hífens e apostrofes'
            }

  # Removed old role validation - now using RBAC system
  # validates :role, inclusion: { in: VALID_ROLES }

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
  scope :active, -> { where.not(last_login_at: nil) }
  scope :inactive, -> { where(last_login_at: nil) }

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

  # Status helpers
  def active?
    persisted? && !deactivated?
  end

  def deactivated?
    # Placeholder for future deactivation feature
    false
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

    default_role = Role.find_by(name: 'user')
    return unless default_role

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
    sanitized.squeeze(' ')
  end

  def sanitize_email(email)
    return nil if email.blank?

    # Basic email sanitization
    sanitized = email.to_s.downcase.strip
    sanitized.gsub(/[<>]/, '')
  end

  def password_not_similar_to_user_info
    return unless password.present?

    # Check if password contains user information
    user_info = [first_name, last_name, email&.split('@')&.first].compact.map(&:downcase)
    password_downcase = password.downcase

    user_info.each do |info|
      next if info.length < 3

      if password_downcase.include?(info)
        errors.add(:password, 'não deve conter informações pessoais como nome ou email')
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
