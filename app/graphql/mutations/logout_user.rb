module Mutations
  class LogoutUser < BaseMutation
    description "Logout current user by invalidating their JWT token"

    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve
      current_token = context[:current_token]

      unless authenticated?
        return { success: false, message: "User not authenticated" }
      end

      # If no token in context, try to extract it directly from headers
      unless current_token
        authorization_header = context[:request]&.headers&.[]('Authorization')
        if authorization_header&.match(/^Bearer\s+(.+)$/i)
          current_token = authorization_header.match(/^Bearer\s+(.+)$/i)[1]
        end
      end

      unless current_token
        return { success: false, message: "No token found" }
      end

      # Blacklist the current token
      JwtService.blacklist_token!(
        current_token,
        current_user.id,
        reason: 'logout'
      )

      {
        success: true,
        message: "Successfully logged out"
      }
    rescue StandardError => e
      Rails.logger.error "Logout error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Logout failed due to an internal error. Please try again.'
      }
    end
  end
end
