# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include AuthorizationHelper
    
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Authentication queries
    field :current_user, UserType, null: true, description: "Returns the currently authenticated user"

    def current_user
      context[:current_user]
    end

    # Admin-only queries
    field :users, [UserType], null: true, description: "List all users (admin only)"

    def users
      authorize!(User, :index?)
      User.all
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
