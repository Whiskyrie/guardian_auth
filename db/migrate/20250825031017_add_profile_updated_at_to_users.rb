class AddProfileUpdatedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_updated_at, :datetime
    add_index :users, :profile_updated_at
  end
end
