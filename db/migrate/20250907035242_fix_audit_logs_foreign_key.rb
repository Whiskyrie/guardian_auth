class FixAuditLogsForeignKey < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing foreign key
    remove_foreign_key :audit_logs, :users
    
    # Add a new foreign key with SET NULL on delete
    add_foreign_key :audit_logs, :users, on_delete: :nullify
  end
  
  def down
    # Remove the new foreign key
    remove_foreign_key :audit_logs, :users
    
    # Add back the original foreign key (CASCADE)
    add_foreign_key :audit_logs, :users
  end
end
