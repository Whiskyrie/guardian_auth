class AddEmailVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_verified_at, :datetime
    add_column :users, :email_verification_digest, :string, limit: 64
    add_column :users, :email_verification_sent_at, :datetime

    add_index :users, :email_verification_digest,
              unique: true,
              where: 'email_verification_digest IS NOT NULL',
              name: 'index_users_on_email_verification_digest'
  end
end
