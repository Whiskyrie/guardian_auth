module Types
  class BaseObject < GraphQL::Schema::Object
    # Inclui AuthorizationHelper para fornecer current_user, authenticated? e authenticate!
    # a resolvers de campos que precisem verificar autenticação/autorização.
    include AuthorizationHelper

    description "Classe base para todos os tipos de objeto GraphQL no sistema Guardian Auth"

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField
  end
end
