class AddTrackingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_login_at, :datetime

    # Adicionar índices para performance
    add_index :users, :role
    add_index :users, :created_at
    add_index :users, :last_login_at
  end
end
