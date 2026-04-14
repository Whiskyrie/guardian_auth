module Mutations
  class LogoutAllDevices < BaseMutation
    description "Logout user from all devices by invalidating all their JWT tokens"

    argument :password, String, required: true, description: "Current password for verification"

    field :success, Boolean, null: false
    field :message, String, null: true
    field :errors, [Types::UserErrorType], null: false, description: 'List of errors'

    def resolve(password:)
      current_user = context[:current_user]

      unless current_user
        return { success: false, message: "User not authenticated", errors: auth_error(Errors::ErrorCodes::AUTHENTICATION_REQUIRED, 'Authentication required') }
      end

      # Verify password before proceeding
      unless current_user.authenticate(password)
        return { success: false, message: "Invalid password", errors: auth_error(Errors::ErrorCodes::INVALID_CREDENTIALS, 'Invalid password') }
      end

      # Invalidate all tokens for this user
      JwtService.blacklist_user_tokens!(
        current_user.id,
        reason: 'admin_logout'
      )

      {
        success: true,
        message: "Successfully logged out from all devices",
        errors: []
      }
    rescue StandardError => e
      Rails.logger.error "Logout all devices error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Logout failed due to an internal error. Please try again.',
        errors: auth_error(
          Errors::ErrorCodes::INTERNAL_ERROR,
          'Logout failed due to an internal error. Please try again.'
        )
      }
    end
  end
end
