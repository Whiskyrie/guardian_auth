module Mutations
  class UpdateUser < BaseMutation
    description 'Update user information'

    argument :id, ID, description: 'ID of user to update'
    argument :input, Types::UserInputType, description: 'User fields to update'

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(id:, input:)
      # Buscar o usuário pelo GlobalID
      user = GlobalID.find(id)

      unless user
        return { user: nil, errors: ['User not found'] }
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

      if user.update(update_attrs)
        # Rastrear atualização de perfil se houve mudanças relevantes
        profile_fields = %w[email first_name last_name]
        profile_changes = update_attrs.keys.map(&:to_s) & profile_fields

        if profile_changes.any? && !current_user&.admin?
          # Verificar se realmente houve mudanças nos valores
          has_real_changes = profile_changes.any? do |field|
            user.public_send("#{field}_previously_was") != user.public_send(field.to_sym)
          end

          if has_real_changes
            user.track_profile_update!
          end
        end

        { user: user, errors: [] }
      else
        { user: nil, errors: user.errors.full_messages }
      end
    end

    private

    def validate_role_change(input)
      return unless input[:role].present?

      return { user: nil, errors: ['Only administrators can change user roles'] } unless current_user&.admin?

      unless User::VALID_ROLES.include?(input[:role])
        return { user: nil, errors: ["Invalid role. Must be one of: #{User::VALID_ROLES.join(', ')}"] }
      end

      nil
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
          errors: ["Você só pode alterar seu perfil uma vez a cada 7 dias. Aguarde #{days_remaining} dia(s)."]
        }
      end

      nil
    end
  end
end
