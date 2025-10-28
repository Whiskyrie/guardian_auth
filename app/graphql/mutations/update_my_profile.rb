# frozen_string_literal: true

module Mutations
  class UpdateMyProfile < BaseMutation
    description 'Update current user profile (no ID needed)'

    argument :input, Types::UserInputType, description: 'User fields to update'

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      # Verificar se o usuário está autenticado
      unless current_user
        return { user: nil, errors: ['Authentication required'] }
      end

      # Não permitir alteração de role em perfil próprio
      if input[:role].present?
        return { user: nil, errors: ['Cannot change your own role. Contact an administrator.'] }
      end

      update_attrs = input.to_h.compact

      if current_user.update(update_attrs)
        { user: current_user, errors: [] }
      else
        { user: nil, errors: current_user.errors.full_messages }
      end
    end
  end
end
