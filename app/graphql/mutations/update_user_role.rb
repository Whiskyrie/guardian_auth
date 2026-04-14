module Mutations
  class UpdateUserRole < BaseMutation

    description "Update user roles (admin only)"

    argument :user_id, ID, required: true, description: "ID of the user to update"
    argument :role_names, [Types::UserRoleEnum], required: true, description: "List of role names to assign"

    field :user, Types::UserType, null: true, description: "Updated user"
    field :success, Boolean, null: false, description: "Whether the operation was successful"
    field :message, String, null: false, description: "Result message"
    field :errors, [Types::UserErrorType], null: false, description: "Any error messages"

    def resolve(user_id:, role_names:)
      authenticate!

      user = User.find_by(id: user_id)

      unless user
        return {
          user: nil,
          success: false,
          message: "User not found",
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, "User with ID #{user_id} does not exist")
        }
      end

      # Check if current user has permission to change roles (admin only)
      unless current_user&.admin?
        return {
          user: nil,
          success: false,
          message: "You are not authorized to modify user roles",
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                             "You are not authorized to modify user roles")
        }
      end

      # Validate that all roles exist with a targeted query (avoids loading all roles into memory)
      found_names = Role.where(name: role_names).pluck(:name)
      invalid_roles = role_names - found_names
      if invalid_roles.any?
        return {
          user: nil,
          success: false,
          message: "Invalid roles provided",
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, "Unknown roles: #{invalid_roles.join(', ')}")
        }
      end

      # Atomic role assignment: all roles applied or none (full rollback on any failure)
      ActiveRecord::Base.transaction do
        user.user_roles.destroy_all

        Role.where(name: role_names).each do |role|
          user.user_roles.create!(
            role: role,
            granted_by: current_user,
            granted_at: Time.current
          )
        end
      end

      {
        user: user.reload,
        success: true,
        message: "User roles updated successfully",
        errors: []
      }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "UpdateUserRole persistence error: #{e.class}: #{e.message}\n" \
                         "#{e.backtrace&.first(5)&.join("\n")}"
      {
        user: nil,
        success: false,
        message: 'Failed to update user roles due to a validation error',
        errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'Role assignment failed due to a validation error')
      }
    rescue StandardError => e
      Rails.logger.error "UpdateUserRole error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        user: nil,
        success: false,
        message: 'An error occurred while updating user roles',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'An internal error occurred while updating user roles')
      }
    end

  end
end
