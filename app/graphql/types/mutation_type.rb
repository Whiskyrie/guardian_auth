module Types
  class MutationType < Types::BaseObject
    field :register_user, mutation: Mutations::RegisterUser
    field :login_user, mutation: Mutations::LoginUser
    field :refresh_token, mutation: Mutations::RefreshToken
    field :logout_user, mutation: Mutations::LogoutUser
    field :logout_all_devices, mutation: Mutations::LogoutAllDevices
  end
end
