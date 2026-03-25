module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include AuthorizationHelper

    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    private

    # Converte erros de validação do ActiveRecord em lista de UserError estruturados.
    # Preenche +field+ com o nome do atributo e +code+ com VALIDATION_FAILED para
    # erros de campo, ou INVALID_INPUT para erros em :base.
    def format_model_errors(record)
      record.errors.map do |error|
        field_name = error.attribute == :base ? nil : error.attribute.to_s
        code = field_name ? Errors::ErrorCodes::VALIDATION_FAILED : Errors::ErrorCodes::INVALID_INPUT
        Types::UserError.new(message: error.full_message, code: code, field: field_name)
      end
    end

    # Cria um array com um único UserError para erros de autenticação, autorização ou negócio.
    def auth_error(code, message)
      [Types::UserError.new(message: message, code: code, field: nil)]
    end
  end
end
