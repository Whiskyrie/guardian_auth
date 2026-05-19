class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti, null: false
      t.inet :ip_address
      t.string :user_agent, limit: 512
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :revoked_reason
      t.timestamps
    end

    add_index :sessions, :jti, unique: true
    add_index :sessions, %i[user_id revoked_at]
    add_index :sessions, :revoked_at, where: 'revoked_at IS NULL', name: 'index_sessions_active'
    add_index :sessions, :expires_at
  end
end
