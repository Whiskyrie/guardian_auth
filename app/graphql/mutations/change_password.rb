module Mutations
  class ChangePassword < BaseMutation
    include RateLimitMutation

    description 'Change user password'
    rate_limited 'changePassword'

    argument :current_password, String, required: true, description: "User's current password"
    argument :new_password, String, required: true, description: "User's new password (minimum 8 characters)"

    field :user, Types::UserType, null: true, description: 'Updated user object'
    field :errors, [Types::UserErrorType], null: false, description: 'List of validation errors'

    def resolve(current_password:, new_password:)
      authenticate!

      user = current_user

      unless user.authenticate(current_password)
        return {
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_CREDENTIALS, 'Senha atual inválida!')
        }
      end

      user.password = new_password

      if user.save
        # Invalidate all existing tokens for security
        user.update!(tokens_valid_after: Time.current)

        {
          user: user,
          errors: []
        }
      else
        {
          user: nil,
          errors: format_model_errors(user)
        }
      end
    rescue StandardError
      {
        user: nil,
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Password change failed. Please try again.')
      }
    end

  end
end
