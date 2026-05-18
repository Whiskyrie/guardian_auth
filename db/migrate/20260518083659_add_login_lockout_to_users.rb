class AddLoginLockoutToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :locked_until, :datetime

    add_index :users, :locked_until, where: 'locked_until IS NOT NULL',
                                     name: 'index_users_on_locked_until'
  end
end
