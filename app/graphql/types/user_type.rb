module Types
  class UserType < Types::BaseObject
    description "Representa um usuário do sistema Guardian Auth"

    field :id, ID, null: false, description: "Identificador único do usuário"
    field :email, String, null: false, description: "Endereço de email do usuário (único no sistema)"
    field :first_name, String, null: true, description: "Primeiro nome do usuário"
    field :last_name, String, null: true, description: "Sobrenome do usuário"
    field :role, String, null: true, description: "Papel/função do usuário no sistema (admin, user, etc.)"
    field :last_login_at, GraphQL::Types::ISO8601DateTime, null: true, 
          description: "Data e hora do último login do usuário"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, 
          description: "Data e hora de criação da conta"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, 
          description: "Data e hora da última atualização dos dados do usuário"

    # Helper fields
    field :full_name, String, null: true, 
          description: "Nome completo do usuário (primeiro nome + sobrenome)"
    field :display_name, String, null: false, 
          description: "Nome de exibição do usuário (nome completo se disponível, senão email)"

    def full_name
      object.full_name
    end

    def display_name
      object.display_name
    end
  end
end
