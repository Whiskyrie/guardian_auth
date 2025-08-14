module Types
  class ErrorType < Types::BaseObject
    description "Representa um erro de validação ou de negócio"

    field :field, String, null: false,
      description: "O campo que gerou o erro"
    
    field :message, String, null: false,
      description: "Mensagem descritiva do erro"
    
    field :code, String, null: false,
      description: "Código do erro para identificação programática"
  end
end
