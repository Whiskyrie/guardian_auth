module Mutations
  class LogoutUser < BaseMutation
    description "Logout current user by invalidating their JWT token"

    field :success, Boolean, null: false
    field :message, String, null: true
    field :errors, [Types::UserErrorType], null: false, description: 'List of errors'

    def resolve
      current_token = context[:current_token]

      unless authenticated?
        return { success: false, message: "User not authenticated", errors: auth_error(Errors::ErrorCodes::AUTHENTICATION_REQUIRED, 'Authentication required') }
      end

      unless current_token
        return { success: false, message: "No token found", errors: auth_error(Errors::ErrorCodes::INVALID_TOKEN, 'No token found') }
      end

      # Blacklist the current token
      JwtService.blacklist_token!(
        current_token,
        current_user.id,
        reason: 'logout'
      )

      {
        success: true,
        message: "Successfully logged out",
        errors: []
      }
    rescue StandardError => e
      Rails.logger.error "Logout error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Logout failed due to an internal error. Please try again.',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Logout failed due to an internal error. Please try again.')
      }
    end
  end
end
