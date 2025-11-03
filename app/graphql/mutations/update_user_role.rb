# frozen_string_literal: true

module Mutations
  class UpdateUserRole < GraphQL::Schema::Mutation
    include AuthorizationHelper

    description "Update user roles (admin only)"

    argument :user_id, ID, required: true, description: "ID of the user to update"
    argument :role_names, [String], required: true, description: "List of role names to assign"

    field :user, Types::UserType, null: true, description: "Updated user"
    field :success, Boolean, null: false, description: "Whether the operation was successful"
    field :message, String, null: false, description: "Result message"
    field :errors, [String], null: true, description: "Any error messages"

    def resolve(user_id:, role_names:)
      user = User.find_by(id: user_id)

      unless user
        return {
          user: nil,
          success: false,
          message: "User not found",
          errors: ["User with ID #{user_id} does not exist"]
        }
      end

      # Check if current user has permission to change roles (admin only)
      unless current_user&.admin?
        return {
          user: nil,
          success: false,
          message: "You are not authorized to modify user roles",
          errors: ["Insufficient permissions"]
        }
      end

      # Validate that all roles exist
      invalid_roles = role_names - Role.pluck(:name)
      if invalid_roles.any?
        return {
          user: nil,
          success: false,
          message: "Invalid roles provided",
          errors: ["Unknown roles: #{invalid_roles.join(', ')}"]
        }
      end

      # Clear existing roles and assign new ones
      user.user_roles.destroy_all

      role_names.each do |role_name|
        user.assign_role(role_name, granted_by: current_user)
      end

      {
        user: user.reload,
        success: true,
        message: "User roles updated successfully",
        errors: nil
      }
    rescue StandardError => e
      {
        user: nil,
        success: false,
        message: "An error occurred while updating user roles",
        errors: [e.message]
      }
    end

    private

    def current_user
      context[:current_user]
    end
  end
end
