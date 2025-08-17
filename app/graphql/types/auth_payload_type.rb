module Types
  class AuthPayloadType < Types::BaseObject
    field :token, String, null: true
    field :user, UserType, null: true
    field :errors, [String], null: false
  end
end
