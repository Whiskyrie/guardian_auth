# frozen_string_literal: true

module Types
  class UserInputType < Types::BaseInputObject
    description 'Input for updating user information'

    argument :first_name, String, required: false, description: "User's first name"
    argument :last_name, String, required: false, description: "User's last name"
    argument :email, String, required: false, description: "User's email address"
    argument :role, String, required: false, description: "User's role (admin only)"
  end
end
