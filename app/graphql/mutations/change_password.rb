module Mutations
  class ChangePassword < BaseMutation
    include RateLimitMutation

    description 'Change user password'
    rate_limited 'changePassword'

    argument :current_password, String, required: true, description: "User's current password"
    argument :new_password, String, required: true, description: "User's new password (minimum 8 characters)"

    field :success, Boolean, null: false, description: 'Whether the password change was successful'
    field :message, String, null: true, description: 'Result message'
    field :user, Types::UserType, null: true, description: 'Updated user object'
    field :errors, [Types::UserErrorType], null: false, description: 'List of validation errors'

    def resolve(current_password:, new_password:)
      unless authenticated?
        return {
          success: false,
          message: 'Authentication required',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::AUTHENTICATION_REQUIRED,
                             'Authentication required. Please provide a valid token.')
        }
      end

      user = current_user

      unless user.authenticate(current_password)
        return {
          success: false,
          message: 'Current password is incorrect',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_CREDENTIALS, 'Current password is incorrect')
        }
      end

      user.password = new_password
      user.password_confirmation = new_password

      if user.save
        # Invalidate all existing tokens for security
        user.update!(tokens_valid_after: Time.current)

        {
          success: true,
          message: 'Password changed successfully. Please login again.',
          user: user,
          errors: []
        }
      else
        {
          success: false,
          message: 'Password change failed',
          user: nil,
          errors: format_model_errors(user)
        }
      end
    rescue StandardError => e
      Rails.logger.error "ChangePassword error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Password change failed. Please try again.',
        user: nil,
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Password change failed. Please try again.')
      }
    end

  end
end
