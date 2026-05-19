class AddDeactivationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :deactivated_at, :datetime
    add_column :users, :deactivated_by_id, :bigint
    add_column :users, :deactivation_reason, :string

    add_index :users, :deactivated_at,
              where: 'deactivated_at IS NOT NULL',
              name: 'index_users_on_deactivated_at_partial'

    add_index :users, :deactivated_by_id,
              name: 'index_users_on_deactivated_by_id'

    add_foreign_key :users, :users,
                    column: :deactivated_by_id,
                    name: 'fk_users_deactivated_by',
                    on_delete: :nullify
  end
end
