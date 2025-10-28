class CreateTokenBlacklists < ActiveRecord::Migration[8.0]
  def change
    create_table :token_blacklists do |t|
      t.string :jti, null: false, index: { unique: true }
      t.datetime :expires_at, null: false, index: true
      t.references :user, foreign_key: true
      t.string :reason # logout, password_change, security_breach

      t.timestamps
    end
  end
end
