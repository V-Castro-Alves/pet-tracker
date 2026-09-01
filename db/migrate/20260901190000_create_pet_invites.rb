class CreatePetInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :pet_invites do |t|
      t.references :pet, null: false, foreign_key: true
      t.string :invite_token, null: false
      t.string :invited_email
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :accepted_by, foreign_key: { to_table: :users }
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :pet_invites, :invite_token, unique: true
    add_index :pet_invites, %i[pet_id expires_at]
  end
end
