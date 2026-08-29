class CreatePetUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :pet_users do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :is_pet_admin, null: false, default: false
      t.datetime :linked_at, null: false

      t.timestamps
    end

    add_index :pet_users, %i[pet_id user_id], unique: true
  end
end
