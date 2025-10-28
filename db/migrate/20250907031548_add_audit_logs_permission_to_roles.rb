class AddAuditLogsPermissionToRoles < ActiveRecord::Migration[8.0]
  def change
    # Create audit_logs permission
    audit_logs_permission = Permission.create!(
      resource: 'audit_logs',
      action: 'read',
      description: 'Permite visualizar logs de auditoria do sistema'
    )

    # Grant permission to admin role
    admin_role = Role.find_by(name: 'admin')
    if admin_role
      RolePermission.create!(
        role: admin_role,
        permission: audit_logs_permission
      )
    end
  end
end
