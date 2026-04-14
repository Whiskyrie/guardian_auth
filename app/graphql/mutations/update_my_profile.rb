module Mutations
  class UpdateMyProfile < BaseMutation
    description 'Update current user profile (no ID needed)'

    argument :input, Types::UserInputType, description: 'User fields to update'

    field :success, Boolean, null: false, description: 'Whether the profile update was successful'
    field :message, String, null: true, description: 'Result message'
    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(input:)
      authenticate!

      # Não permitir alteração de role em perfil próprio
      if input[:role].present?
        return {
          success: false,
          message: 'Cannot change your own role',
          user: nil,
          errors: auth_error(
            Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
            'Cannot change your own role. Contact an administrator.'
          )
        }
      end

      update_attrs = input.to_h.compact

      if current_user.update(update_attrs)
        { success: true, message: 'Profile updated successfully', user: current_user, errors: [] }
      else
        { success: false, message: 'Profile update failed', user: nil, errors: format_model_errors(current_user) }
      end
    end
  end
end
