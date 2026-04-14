module Types
  class UserInputType < Types::BaseInputObject
    description 'Input type for updating user information'

    argument :first_name, String, required: false,
                                  description: "User's first name"

    argument :last_name, String, required: false,
                                 description: "User's last name"

    argument :email, String, required: false,
                             description: "User email address (must be unique in the system)"

    argument :role, Types::UserRoleEnum, required: false,
                                         description: "User role in the system (only administrators can change this)"
  end
end
