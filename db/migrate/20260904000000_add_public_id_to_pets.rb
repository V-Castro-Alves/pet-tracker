class AddPublicIdToPets < ActiveRecord::Migration[8.1]
  def up
    add_column :pets, :public_id, :string

    Pet.reset_column_information
    Pet.find_each { |pet| pet.update_column(:public_id, SecureRandom.uuid) }

    change_column_null :pets, :public_id, false
    add_index :pets, :public_id, unique: true
  end

  def down
    remove_column :pets, :public_id
  end
end
