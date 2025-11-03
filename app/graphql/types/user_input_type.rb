# frozen_string_literal: true

module Types
  class UserInputType < Types::BaseInputObject
    description 'Entrada de dados para atualização de informações do usuário'

    argument :first_name, String, required: false,
                                  description: "Primeiro nome do usuário"

    argument :last_name, String, required: false,
                                 description: "Sobrenome do usuário"

    argument :email, String, required: false,
                             description: "Endereço de email do usuário (deve ser único no sistema)"

    argument :role, String, required: false,
                            description: "Papel/função do usuário no sistema (apenas administradores podem alterar)"
  end
end
