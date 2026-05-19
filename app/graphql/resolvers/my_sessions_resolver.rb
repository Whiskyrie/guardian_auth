module Resolvers
  class MySessionsResolver < BaseResolver
    type [Types::SessionType], null: false
    description 'Lista as sessões ativas do usuário autenticado'

    def resolve
      authenticate!
      base = current_user.sessions.active.order(created_at: :desc)

      # Exclude sessions issued before tokens_valid_after (mass-invalidated)
      if current_user.tokens_valid_after.present?
        base = base.where('sessions.created_at >= ?', current_user.tokens_valid_after)
      end

      base
    end
  end
end
