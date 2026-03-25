module Mutations
  class UpdateMyProfile < BaseMutation
    description 'Update current user profile (no ID needed)'

    argument :input, Types::UserInputType, description: 'User fields to update'

    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(input:)
      authenticate!

      # Não permitir alteração de role em perfil próprio
      if input[:role].present?
        return { user: nil, errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS, 'Cannot change your own role. Contact an administrator.') }
      end

      update_attrs = input.to_h.compact

      if current_user.update(update_attrs)
        { user: current_user, errors: [] }
      else
        { user: nil, errors: format_model_errors(current_user) }
      end
    end
  end
end
