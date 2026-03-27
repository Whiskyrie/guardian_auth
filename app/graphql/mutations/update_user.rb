module Mutations
  class UpdateUser < BaseMutation
    description 'Update user information'

    argument :id, ID, description: 'ID of user to update'
    argument :input, Types::UserInputType, description: 'User fields to update'

    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(id:, input:)
      # Buscar o usuário pelo GlobalID
      user = GlobalID.find(id)

      unless user
        return { user: nil, errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, 'User not found') }
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
        return { user: nil, errors: format_model_errors(e.record) }
      end

      # Rastrear atualização de perfil se houve mudanças relevantes
      profile_fields = %w[email first_name last_name]
      profile_changes = user.previous_changes.keys & profile_fields
      user.track_profile_update! if profile_changes.any? && !current_user&.admin?

      { user: user.reload, errors: [] }
    end

    private

    def validate_role_change(input)
      return unless input[:role].present?

      unless current_user&.admin?
        return { user: nil,
                 errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                                    'Only administrators can change user roles') }
      end

      unless Role.exists?(name: input[:role])
        return { user: nil,
                 errors: auth_error(Errors::ErrorCodes::INVALID_INPUT,
                                    "Role '#{input[:role]}' is not configured in the system") }
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
          user: nil,
          errors: auth_error(Errors::ErrorCodes::VALIDATION_FAILED,
                             "Você só pode alterar seu perfil uma vez a cada 7 dias. Aguarde #{days_remaining} dia(s).")
        }
      end

      nil
    end
  end
end
