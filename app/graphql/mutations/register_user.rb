module Mutations
  class RegisterUser < BaseMutation
    description "Register a new user account"

    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true, description: "User's password (minimum 6 characters)"
    argument :first_name, String, required: true, description: "User's first name"
    argument :last_name, String, required: true, description: "User's last name"
    
    field :token, String, null: true, description: "JWT authentication token"
    field :user, Types::UserType, null: true, description: "Created user object"
    field :errors, [String], null: false, description: "List of validation errors"
    
    def resolve(email:, password:, first_name:, last_name:)
      # Normalize email
      email = email.downcase.strip
      
      user = User.new(
        email: email,
        password: password,
        first_name: first_name.strip,
        last_name: last_name.strip
      )
      
      if user.save
        token = JwtService.encode(user_id: user.id)
        {
          auth_payload: {
            token: token,
            user: user,
            errors: []
          }
        }
      else
        {
          auth_payload: {
            token: nil,
            user: nil,
            errors: user.errors.full_messages
          }
        }
      end
    rescue StandardError => e
      Rails.logger.error "RegisterUser mutation error: #{e.message}"
      {
        token: nil,
        user: nil,
        errors: ["Registration failed. Please try again."]
      }
    end
  end
end