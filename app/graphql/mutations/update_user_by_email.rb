module Mutations
  class UpdateUserByEmail < BaseMutation
    description 'Update user information by email'

    argument :email, String, description: 'Email of user to update'
    argument :input, Types::UserInputType, description: 'User fields to update'

    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(email:, input:)
      # Buscar o usuário pelo email
      user = User.find_by_email(email)

      unless user
        return { user: nil, errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, 'User not found') }
      end

      # Verificar autorização usando Pundit
      authorize!(user, :update?)

      role_validation = validate_role_change(input)
      return role_validation if role_validation

      update_attrs = input.to_h.compact

      if user.update(update_attrs)
        { user: user, errors: [] }
      else
        { user: nil, errors: format_model_errors(user) }
      end
    end

    private

    def validate_role_change(input)
      return unless input[:role].present?

      unless current_user&.admin?
        return { user: nil,
                 errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                                    'Only administrators can change user roles') }
      end

      unless User::VALID_ROLES.include?(input[:role])
        return { user: nil, errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, "Invalid role. Must be one of: #{User::VALID_ROLES.join(', ')}") }
      end

      nil
    end
  end
end
