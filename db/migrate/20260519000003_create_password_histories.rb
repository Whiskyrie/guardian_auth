class CreatePasswordHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :password_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :password_digest, null: false

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :password_histories, %i[user_id created_at]
  end
end
