class ChangeAuditLogMetadataToJsonb < ActiveRecord::Migration[8.0]
  def up
    change_column :audit_logs, :metadata, :jsonb, using: 'metadata::jsonb'
    add_index :audit_logs, :metadata, using: :gin, name: 'index_audit_logs_on_metadata'
  end

  def down
    remove_index :audit_logs, name: 'index_audit_logs_on_metadata'
    change_column :audit_logs, :metadata, :json
  end
end
