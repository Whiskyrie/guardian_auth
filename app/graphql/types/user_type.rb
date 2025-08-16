module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :role, String, null: true
    field :last_login_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Helper fields
    field :full_name, String, null: true, description: "User's full name"
    field :display_name, String, null: false, description: "User's display name (full name or email)"

    def full_name
      object.full_name
    end

    def display_name
      object.display_name
    end
  end
end
