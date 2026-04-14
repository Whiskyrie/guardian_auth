module Mutations
  class RegisterUser < BaseMutation
    include RateLimitMutation

    description 'Register a new user account'
    rate_limited 'registerUser'

    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true,
                                description: "Min 8 chars, must include " \
                                             "uppercase, lowercase, digit, and special char"
    argument :first_name, String, required: true, description: "User's first name"
    argument :last_name, String, required: true, description: "User's last name"

    field :success, Boolean, null: false, description: 'Whether the registration was successful'
    field :message, String, null: true, description: 'Result message'
    field :token, String, null: true, description: 'JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Created user object'
    field :errors, [Types::UserErrorType], null: false, description: 'List of validation errors'

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
          success: true,
          message: 'Registration successful',
          token: token,
          user: user,
          errors: []
        }
      else
        {
          success: false,
          message: 'Registration failed',
          token: nil,
          user: nil,
          errors: format_model_errors(user)
        }
      end
    rescue StandardError => e
      Rails.logger.error "RegisterUser mutation error: #{e.message}"
      {
        success: false,
        message: 'Registration failed. Please try again.',
        token: nil,
        user: nil,
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Registration failed. Please try again.')
      }
    end
  end
end
