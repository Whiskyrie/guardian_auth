module Resolvers
  class UserSessionsResolver < BaseResolver
    type [Types::SessionType], null: false
    description 'Lista sessões ativas de um usuário específico (apenas administradores)'

    argument :user_id, ID, required: true, description: 'ID do usuário'

    def resolve(user_id:)
      authenticate!

      unless current_user.admin?
        raise GraphQL::ExecutionError, 'Apenas administradores podem listar sessões de outros usuários'
      end

      target = User.find_by(id: user_id)
      raise GraphQL::ExecutionError, 'Usuário não encontrado' unless target

      base = target.sessions.active.order(created_at: :desc)

      if target.tokens_valid_after.present?
        base = base.where('sessions.created_at >= ?', target.tokens_valid_after)
      end

      base
    end
  end
end
