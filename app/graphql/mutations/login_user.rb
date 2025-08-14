module Mutations
  class LoginUser < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    
    field :auth_payload, Types::AuthPayloadType, null: false
    
    def resolve(email:, password:)
      user = User.find_by(email: email)
      
      if user&.authenticate(password)
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
            errors: ["Senha ou email inválidos!"]
          }
        }
      end
    end
  end
end