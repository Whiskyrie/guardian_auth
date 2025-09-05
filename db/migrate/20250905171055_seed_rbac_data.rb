class SeedRbacData < ActiveRecord::Migration[8.0]
  def up
    # Create basic roles using raw SQL to avoid model loading issues
    execute <<~SQL
      INSERT INTO roles (name, description, system_role, metadata, created_at, updated_at)
      VALUES 
        ('admin', 'Administrador do sistema', true, '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('user', 'Usuário padrão do sistema', true, '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    
    # Create basic permissions
    permissions_data = [
      # User permissions
      ['users', 'create', 'Criar novos usuários'],
      ['users', 'read', 'Ler dados de usuários'],
      ['users', 'update', 'Atualizar dados de usuários'],
      ['users', 'delete', 'Deletar usuários'],
      ['users', 'read_own', 'Ler próprios dados'],
      ['users', 'update_own', 'Atualizar próprios dados'],
      ['users', 'list', 'Listar usuários'],
      
      # Role permissions
      ['roles', 'create', 'Criar roles'],
      ['roles', 'read', 'Ler roles'],
      ['roles', 'update', 'Atualizar roles'],
      ['roles', 'delete', 'Deletar roles'],
      ['roles', 'assign', 'Atribuir roles a usuários'],
      
      # System permissions
      ['system', 'admin', 'Acesso administrativo total'],
      ['system', 'health_check', 'Verificar saúde do sistema']
    ]
    
    # Insert permissions
    permissions_data.each do |resource, action, description|
      execute <<~SQL
        INSERT INTO permissions (resource, action, description, metadata, created_at, updated_at)
        VALUES (#{connection.quote(resource)}, #{connection.quote(action)}, #{connection.quote(description)}, '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end
    
    # Assign all permissions to admin role
    execute <<~SQL
      INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
      SELECT r.id, p.id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM roles r, permissions p
      WHERE r.name = 'admin'
    SQL
    
    # Assign limited permissions to user role
    execute <<~SQL
      INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
      SELECT r.id, p.id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM roles r, permissions p
      WHERE r.name = 'user' 
      AND p.action IN ('read_own', 'update_own', 'health_check')
    SQL
    
    # Display results
    role_count = connection.execute("SELECT COUNT(*) FROM roles").first.values.first
    permission_count = connection.execute("SELECT COUNT(*) FROM permissions").first.values.first
    role_permission_count = connection.execute("SELECT COUNT(*) FROM role_permissions").first.values.first
    
    say "✅ RBAC seed data created successfully!"
    say "🔑 Roles created: #{role_count}"
    say "🛡️  Permissions created: #{permission_count}"
    say "🔗 Role-Permission associations: #{role_permission_count}"
  end
  
  def down
    execute "DELETE FROM role_permissions"
    execute "DELETE FROM permissions"
    execute "DELETE FROM roles"
  end
end
