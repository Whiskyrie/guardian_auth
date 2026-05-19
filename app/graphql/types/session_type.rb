module Types
  class SessionType < Types::BaseObject
    description 'Representa uma sessão ativa de usuário no Guardian Auth'

    field :id, ID, null: false, description: 'Identificador único da sessão'
    field :ip_address, String, null: true, description: 'Endereço IP de origem da sessão'
    field :user_agent, String, null: true, description: 'User-Agent do cliente'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false,
                                                        description: 'Data e hora de criação da sessão'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: false,
                                                        description: 'Data e hora de expiração do token'
    field :current, Boolean, null: false,
                             description: 'Indica se esta é a sessão da requisição atual'

    def ip_address
      object.ip_address&.to_s
    end

    def current
      current_token = context[:current_token]
      return false unless current_token

      JwtService.extract_jti_from_token(current_token) == object.jti
    end
  end
end
