# frozen_string_literal: true

module Types
  class UserRoleEnum < Types::BaseEnum
    description "User role types"
    
    value "USER", "Regular user", value: "user"
    value "ADMIN", "Administrator", value: "admin"
  end
end
