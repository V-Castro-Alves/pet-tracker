class AddUserPublicIds < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :public_id, :string
    select_values("SELECT id FROM users").each do |id|
      execute "UPDATE users SET public_id = '#{SecureRandom.uuid}' WHERE id = #{Integer(id)}"
    end
    change_column_null :users, :public_id, false
    add_index :users, :public_id, unique: true
  end
  def down
    remove_column :users, :public_id
  end
end
