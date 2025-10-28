module Types
  class AuthPayloadType < Types::BaseObject
    description "Payload de resposta para operações de autenticação"

    field :token, String, null: true, 
          description: "Token JWT de acesso para autenticação nas próximas requisições"
    
    field :user, UserType, null: true, 
          description: "Dados do usuário autenticado"
    
    field :errors, [String], null: false, 
          description: "Lista de erros que ocorreram durante a operação de autenticação"
  end
end
