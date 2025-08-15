module Mutations
  class RegisterUser < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    
    field :auth_payload, Types::AuthPayloadType, null: false
    
    def resolve(email:, password:, first_name:, last_name:)
      user = User.new(
        email: email,
        password: password,
        first_name: first_name,
        last_name: last_name
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
    end
  end
end