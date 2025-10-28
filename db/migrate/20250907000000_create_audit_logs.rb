class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, foreign_key: true, null: true
      t.string :action, null: false, comment: "login, logout, register, etc"
      t.string :resource, null: false, comment: "User, Token, etc"
      t.string :resource_id
      t.json :metadata, comment: "IP, user_agent, changes, request_id"
      t.string :result, null: false, comment: "success, failure, blocked"
      t.datetime :created_at, null: false
      
      t.index [:user_id, :created_at]
      t.index [:action, :created_at]
      t.index [:result, :created_at]
      t.index [:resource, :resource_id]
    end
    
    add_check_constraint :audit_logs, "result IN ('success', 'failure', 'blocked')", name: "valid_audit_result"
    add_check_constraint :audit_logs, "action IS NOT NULL", name: "audit_action_not_null"
    add_check_constraint :audit_logs, "resource IS NOT NULL", name: "audit_resource_not_null"
  end
end
