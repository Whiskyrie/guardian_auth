# frozen_string_literal: true

module Mutations
  class LogoutAllDevices < BaseMutation
    description "Logout user from all devices by invalidating all their JWT tokens"

    argument :password, String, required: true, description: "Current password for verification"

    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve(password:)
      current_user = context[:current_user]

      unless current_user
        return { success: false, message: "User not authenticated" }
      end

      # Verify password before proceeding
      unless current_user.authenticate(password)
        return { success: false, message: "Invalid password" }
      end

      # Invalidate all tokens for this user
      JwtService.blacklist_user_tokens!(
        current_user.id,
        reason: 'admin_logout'
      )

      {
        success: true,
        message: "Successfully logged out from all devices"
      }
    rescue StandardError => e
      Rails.logger.error "Logout all devices error: #{e.message}"
      {
        success: false,
        message: "Logout failed: #{e.message}"
      }
    end
  end
end
