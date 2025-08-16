class User < ApplicationRecord
  has_secure_password

  # Constants
  VALID_ROLES = %w[user admin].freeze
  EMAIL_REGEX = /\A[a-zA-Z0-9][\w+\-.]*@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.freeze
  PASSWORD_REGEX = /\A(?=.*[a-zA-Z])(?=.*\d).{8,}\z/.freeze

  # Validations
  validates :email, 
            presence: true, 
            uniqueness: { case_sensitive: false },
            format: { 
              with: EMAIL_REGEX,
              message: "deve ter um formato válido"
            },
            length: { maximum: 255 }

  validates :password, 
            length: { minimum: 8, maximum: 128 }, 
            format: { 
              with: PASSWORD_REGEX, 
              message: "deve conter pelo menos 8 caracteres, incluindo letras e números" 
            },
            if: -> { new_record? || !password.nil? }

  validates :first_name, :last_name, 
            presence: true, 
            length: { minimum: 2, maximum: 50 },
            format: { 
              with: /\A[a-zA-ZÀ-ÿ\s'-]+\z/,
              message: "deve conter apenas letras, espaços, hífens e apostrofes"
            }

  validates :role, inclusion: { in: VALID_ROLES }

  # Callbacks
  before_validation :normalize_email, on: [:create, :update]
  before_validation :set_default_role, on: :create

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
    self.role ||= "user"
  end
end
