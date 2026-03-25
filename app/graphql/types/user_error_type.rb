# frozen_string_literal: true

module Types
  # Struct de valor para carregar dados de erro antes da serialização GraphQL.
  # Permite que helpers como `format_model_errors` e `auth_error` retornem objetos
  # com métodos em vez de hashes simples, garantindo resolução correta pelos campos GraphQL.
  UserError = Struct.new(:message, :code, :field, keyword_init: true)

  class UserErrorType < Types::BaseObject
    description 'Erro estruturado com código e campo para identificação programática'

    field :message, String, null: false,
                            description: 'Mensagem legível para o usuário'

    field :code, String, null: true,
                         description: 'Código de erro estruturado (ex: VALIDATION_FAILED, AUTHENTICATION_REQUIRED)'

    field :field, String, null: true,
                          description: 'Nome do campo que causou o erro em erros de validação (ex: "email")'
  end
end
