module Mutations
  class UpdateUser < BaseMutation
    description 'Update user information'

    argument :id, ID, description: 'ID of user to update'
    argument :input, Types::UserInputType, description: 'User fields to update'

    field :success, Boolean, null: false, description: 'Whether the update was successful'
    field :message, String, null: true, description: 'Result message'
    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(id:, input:)
      user = resolve_user(id)

      unless user
        return {
          success: false,
          message: 'User not found',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, 'User not found')
        }
      end

      # Verificar autorização usando Pundit
      authorize!(user, :update?)

      # Validar mudanças de role
      role_validation = validate_role_change(input)
      return role_validation if role_validation

      # Validar frequência de atualização de perfil
      profile_validation = validate_profile_update_frequency(user, input)
      return profile_validation if profile_validation

      update_attrs = input.to_h.compact
      requested_role = update_attrs.delete(:role)

      begin
        ActiveRecord::Base.transaction do
          user.update!(update_attrs)
          apply_role_change!(user, requested_role) if requested_role.present?
        end
      rescue ActiveRecord::RecordInvalid => e
        return { success: false, message: 'Update failed', user: nil, errors: format_model_errors(e.record) }
      end

      # Rastrear atualização de perfil se houve mudanças relevantes
      profile_fields = %w[email first_name last_name]
      profile_changes = user.previous_changes.keys & profile_fields
      user.track_profile_update! if profile_changes.any? && !current_user&.admin?

      { success: true, message: 'User updated successfully', user: user.reload, errors: [] }
    end

    private

    def resolve_user(id)
      # Support GlobalID resolution (e.g. from Relay)
      # to_gid_param returns base64-encoded GlobalID, try parsing it first
      gid = GlobalID.parse(id) || GlobalID.parse(Base64.urlsafe_decode64(id.to_s))
      if gid
        record = GlobalID::Locator.locate(gid)
        record.is_a?(User) ? record : nil
      else
        User.find_by(id: id)
      end
    rescue StandardError
      nil
    end

    def validate_role_change(input)
      return unless input[:role].present?

      unless current_user&.admin?
        return {
          success: false,
          message: 'Only administrators can change user roles',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                             'Only administrators can change user roles')
        }
      end

      unless Role.exists?(name: input[:role])
        return {
          success: false,
          message: 'Role not found',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT,
                             "Role '#{input[:role]}' is not configured in the system")
        }
      end

      nil
    end

    def apply_role_change!(user, role_name)
      role = Role.find_by(name: role_name)
      return unless role

      user.user_roles.where.not(role_id: role.id).destroy_all
      user.user_roles.find_or_create_by!(role: role) do |user_role|
        user_role.granted_by = current_user
        user_role.granted_at = Time.current
      end
    end

    def validate_profile_update_frequency(user, input)
      # Admins não têm restrição temporal
      return nil if current_user&.admin?

      # Verificar se há mudanças nos campos de perfil
      profile_fields = %w[email first_name last_name]
      profile_changes = input.to_h.keys.map(&:to_s) & profile_fields

      return nil if profile_changes.empty?

      # Verificar se realmente há mudanças nos valores
      has_real_changes = profile_changes.any? do |field|
        current_value = user.public_send(field.to_sym)
        new_value = input[field.to_sym]
        current_value != new_value
      end

      return nil unless has_real_changes

      # Verificar limitação temporal
      unless user.can_update_profile?
        days_since_update = ((Time.current - user.profile_updated_at) / 1.day).floor
        days_remaining = 7 - days_since_update
        return {
          success: false,
          message: 'Profile update cooldown active',
          user: nil,
          errors: auth_error(
            Errors::ErrorCodes::VALIDATION_FAILED,
            "You can only update your profile once every 7 days. " \
            "Please wait #{days_remaining} day(s)."
          )
        }
      end

      nil
    end
  end
end
