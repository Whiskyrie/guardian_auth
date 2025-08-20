# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :register_user, mutation: Mutations::RegisterUser
    field :login_user, mutation: Mutations::LoginUser
    field :change_password, mutation: Mutations::ChangePassword
    field :refresh_token, mutation: Mutations::RefreshToken
    field :logout_user, mutation: Mutations::LogoutUser
    field :logout_all_devices, mutation: Mutations::LogoutAllDevices
    field :update_user, mutation: Mutations::UpdateUser
    field :update_user_by_email, mutation: Mutations::UpdateUserByEmail
    field :update_my_profile, mutation: Mutations::UpdateMyProfile
  end
end
