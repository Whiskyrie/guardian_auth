module Types
  class AuthPayloadType < Types::BaseObject
    field :token, String, null: false
    field :user, UserType, null: false
    field :errors, [String], null: false
  end
end
