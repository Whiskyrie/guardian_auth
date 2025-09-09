# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "Ponto de entrada para todas as consultas no sistema Guardian Auth"
    
    include AuthorizationHelper

    # Relay Node interface
    field :node, Types::NodeType, null: true, 
          description: 'Busca um objeto pelo seu ID global único (Global ID)' do
      argument :id, ID, required: true, 
               description: 'ID global único do objeto a ser buscado'
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, { null: true }], null: true,
          description: 'Busca uma lista de objetos pelos seus IDs globais únicos' do
      argument :ids, [ID], required: true, 
               description: 'Lista de IDs globais únicos dos objetos a serem buscados'
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Authentication queries
    field :current_user, UserType, null: true, 
          description: 'Retorna o usuário atualmente autenticado baseado no token JWT' do
      description 'Obtém informações do usuário logado através do token JWT no header Authorization'
    end

    def current_user
      # Returns the user from JWT token or nil if not authenticated
      context[:current_user]
    end

    # Admin-only queries
    field :users, resolver: Resolvers::UsersResolver,
          max_page_size: 50,        # Limita este campo específico
          default_page_size: 10,    # Padrão menor para este campo
          description: 'Lista todos os usuários com filtros e paginação (apenas administradores)'

    field :user, UserType, null: true, 
          description: 'Busca um usuário específico pelo ID (apenas administradores)' do
      argument :id, ID, required: true, 
               description: 'O ID do usuário a ser buscado'
    end

    # Audit logs (admin only)
    field :audit_logs, resolver: Resolvers::AuditLogsResolver,
          max_page_size: 100,       # Allow larger page size for audit logs
          default_page_size: 20,     # Default page size for audit logs
          description: 'Consulta logs de auditoria para monitoramento de segurança (apenas administradores)'

    # Health check and system info
    field :test_field, String, null: false,
          description: 'Campo de teste para verificar conectividade da API',
          deprecation_reason: "Este campo será removido em versões futuras. Use health checks específicos."
    
    def test_field
      'Hello World!'
    end
  end
end
