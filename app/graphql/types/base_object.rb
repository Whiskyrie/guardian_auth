module Types
  class BaseObject < GraphQL::Schema::Object
    description "Classe base para todos os tipos de objeto GraphQL no sistema Guardian Auth"

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    # Helper method to access current_user from context
    def current_user
      context[:current_user]
    end

    # Helper method to check if user is authenticated
    def authenticated?
      current_user.present?
    end

    # Helper method to require authentication
    def authenticate!
      return true if authenticated?

      raise GraphQL::ExecutionError, 'Authentication required. Please provide a valid token.'
    end
  end
end
