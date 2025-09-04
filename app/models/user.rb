class User < ApplicationRecord
  has_secure_password

  # Constants
  VALID_ROLES = %w[user admin].freeze
  EMAIL_REGEX = /\A[a-zA-Z0-9][\w+\-.]*@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  
  # Strong password requirements: min 8 chars, at least one uppercase, lowercase, digit, and special char
  PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}\z/
  
  # Common weak passwords to reject
  WEAK_PASSWORDS = %w[
    password 12345678 password123 admin123 qwerty123 letmein123
    welcome123 password1 123456789 qwertyuiop adminadmin useruser
  ].freeze

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

  validates :role, inclusion: { in: VALID_ROLES }

  # Custom validation for password strength
  validate :password_not_similar_to_user_info, if: -> { password.present? }

  # Callbacks
  before_validation :normalize_email, on: %i[create update]
  before_validation :set_default_role, on: :create
  before_save :sanitize_user_inputs

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :users, -> { where(role: 'user') }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where.not(last_login_at: nil) }
  scope :inactive, -> { where(last_login_at: nil) }

  # Role helper methods
  def admin?
    role == 'admin'
  end

  def user?
    role == 'user'
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

  def set_default_role
    self.role ||= 'user'
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
    sanitized = sanitized.gsub(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi, '')
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
        errors.add(:password, 'não deve conter informações pessoais como nome ou email')
        break
      end
    end
  end
end
