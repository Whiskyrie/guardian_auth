class UserRole < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :role
  belongs_to :granted_by, class_name: 'User', optional: true

  # Validations
  validates :user_id, uniqueness: { scope: :role_id }

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :for_role, ->(role) { where(role: role) }
  scope :granted_by_user, ->(user) { where(granted_by: user) }
  scope :recent, -> { order(granted_at: :desc) }

  # Callbacks
  before_validation :set_granted_at, on: :create

  # Instance methods
  def role_name
    role.name
  end

  def user_name
    user.display_name
  end

  def granted_by_name
    granted_by&.display_name || 'Sistema'
  end

  def granted_recently?(time_frame = 24.hours)
    granted_at > time_frame.ago
  end

  private

  def set_granted_at
    self.granted_at ||= Time.current
  end
end
