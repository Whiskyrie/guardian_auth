module Types
  class AuthPayloadType < Types::BaseObject
    description "Response payload for authentication operations"

    field :token, String, null: true,
                          description: "JWT access token for authenticating subsequent requests"

    field :user, UserType, null: true,
                           description: "Authenticated user data"

    field :errors, [Types::UserErrorType], null: false,
                                           description: "List of errors from the authentication operation"
  end
end
