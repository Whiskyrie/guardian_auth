class RemoveRoleFromUsers < ActiveRecord::Migration[8.0]
  def up
    # Remove legacy role column — RBAC system is now the source of truth
    remove_column :users, :role, :string if column_exists?(:users, :role)

    # Remove unused password reset columns that have no implementation
    remove_column :users, :password_reset_attempts, :integer if column_exists?(:users, :password_reset_attempts)
    remove_column :users, :last_password_reset_at, :datetime if column_exists?(:users, :last_password_reset_at)
    remove_column :users, :password_reset_locked_until, :datetime if column_exists?(:users, :password_reset_locked_until)
  end

  def down
    add_column :users, :role, :string unless column_exists?(:users, :role)
    add_column :users, :password_reset_attempts, :integer, default: 0 unless column_exists?(:users, :password_reset_attempts)
    add_column :users, :last_password_reset_at, :datetime unless column_exists?(:users, :last_password_reset_at)
    add_column :users, :password_reset_locked_until, :datetime unless column_exists?(:users, :password_reset_locked_until)

    add_index :users, :role if column_exists?(:users, :role)
  end
end
