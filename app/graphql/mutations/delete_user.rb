module Mutations
  class DeleteUser < BaseMutation

    description "Delete a user account (admin only)"

    argument :id, ID, required: true, description: "ID of the user to delete"

    field :success, Boolean, null: false, description: "Whether the deletion was successful"
    field :message, String, null: false, description: "Confirmation message"
    field :errors, [Types::UserErrorType], null: false, description: "Any error messages"

    def resolve(id:)
      authenticate!

      user = User.find_by(id: id)

      unless user
        return {
          success: false,
          message: "User not found",
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, "User with ID #{id} does not exist")
        }
      end

      # Apply authorization policy
      authorize!(user, :destroy?)

      if user.destroy
        {
          success: true,
          message: "User #{user.email} has been successfully deleted",
          errors: []
        }
      else
        {
          success: false,
          message: "Failed to delete user",
          errors: format_model_errors(user)
        }
      end
    rescue StandardError => e
      Rails.logger.error "DeleteUser error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'An error occurred while deleting the user',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'An internal error occurred while deleting the user')
      }
    end

  end
end
