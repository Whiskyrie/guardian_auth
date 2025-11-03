module Mutations
  class DeleteUser < GraphQL::Schema::Mutation
    include AuthorizationHelper

    description "Delete a user account (admin only)"

    argument :id, ID, required: true, description: "ID of the user to delete"

    field :success, Boolean, null: false, description: "Whether the deletion was successful"
    field :message, String, null: false, description: "Confirmation message"
    field :errors, [String], null: true, description: "Any error messages"

    def resolve(id:)
      user = User.find_by(id: id)

      unless user
        return {
          success: false,
          message: "User not found",
          errors: ["User with ID #{id} does not exist"]
        }
      end

      # Apply authorization policy
      authorize!(user, :destroy?)

      if user.destroy
        {
          success: true,
          message: "User #{user.email} has been successfully deleted",
          errors: nil
        }
      else
        {
          success: false,
          message: "Failed to delete user",
          errors: user.errors.full_messages
        }
      end
    rescue GraphQL::ExecutionError => e
      {
        success: false,
        message: e.message,
        errors: ["not authorized"]
      }
    rescue StandardError => e
      {
        success: false,
        message: "An error occurred while deleting the user",
        errors: [e.message]
      }
    end

    private

    def current_user
      context[:current_user]
    end
  end
end
