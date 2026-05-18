module Resolvers
  class UsersResolver < BaseResolver
    type Types::UserType.connection_type, null: false
    description "List users with filters and pagination (admin only)"

    # Argumentos com filtros
    argument :role, Types::UserRoleEnum, required: false, description: "Filter by user role"
    argument :search, String, required: false, description: "Search by name or email"
    argument :created_after, GraphQL::Types::ISO8601Date, required: false,
                                                          description: "Show users created after this date"
    argument :created_before, GraphQL::Types::ISO8601Date, required: false,
                                                           description: "Show users created before this date"

    def resolve(**args)
      # Aplicar autorização primeiro
      authorize!(User, :index?)

      # Construir query com filtros e eager loading para prevenir N+1
      users = apply_filters(User.all, args)
      users = users.includes(:roles) # Prevenção de N+1 queries

      # GraphQL-Ruby aplicará paginação automaticamente
      users.order(:created_at)
    end

    private

    def sanitize_search(term)
      stripped = term.to_s.strip
      return nil if stripped.length < 2 || stripped.length > 50

      # Escapa wildcards do SQL LIKE para evitar full table scans intencionais
      stripped.gsub(/[%_\\]/) { |c| "\\#{c}" }
    end

    def apply_filters(scope, filters)
      # Filter by role using RBAC system
      if filters[:role].present?
        scope = scope.joins(:roles).where(roles: { name: filters[:role] })
      end

      if filters[:search].present?
        sanitized = sanitize_search(filters[:search])
        if sanitized
          term = "%#{sanitized}%"
          scope = scope.where(
            "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
            term, term, term
          )
        end
      end

      scope = scope.where("created_at >= ?", filters[:created_after]) if filters[:created_after].present?
      scope = scope.where("created_at <= ?", filters[:created_before]) if filters[:created_before].present?

      scope
    end
  end
end
