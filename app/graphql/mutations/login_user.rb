module Mutations
  class LoginUser < BaseMutation
    description 'Authenticate user and return access token'

    argument :email, String, required: true, description: "User's email address"
    argument :password, String, required: true, description: "User's password"

    field :token, String, null: true, description: 'JWT authentication token'
    field :user, Types::UserType, null: true, description: 'Authenticated user object'
    field :errors, [String], null: false, description: 'List of authentication errors'

    def resolve(email:, password:)
      # Normalize email
      email = email.downcase.strip

      user = User.find_by(email: email)

      if user&.authenticate(password)
        token = JwtService.encode(user_id: user.id)
        {
          token: token,
          user: user,
          errors: []
        }
      else
        {
          token: nil,
          user: nil,
          errors: ['Email ou senha inválidos!']
        }
      end
    rescue StandardError => e
      Rails.logger.error "LoginUser mutation error: #{e.message}"
      {
        token: nil,
        user: nil,
        errors: ['Authentication failed. Please try again.']
      }
    end
  end
end
