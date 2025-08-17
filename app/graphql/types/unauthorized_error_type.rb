# frozen_string_literal: true

module Types
  class UnauthorizedErrorType < Types::BaseObject
    description 'Erro de autorização quando usuário não tem permissão'

    field :message, String, null: false, description: 'Mensagem de erro'
    field :code, String, null: false, description: 'Código do erro'

    def message
      'Not authorized'
    end

    def code
      'UNAUTHORIZED'
    end
  end
end
