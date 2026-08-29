class CreatePets < ActiveRecord::Migration[8.1]
  def change
    create_table :pets do |t|
      t.string :name, null: false
      t.string :species, null: false
      t.string :breed
      t.date :birthdate
      t.string :sex
      t.text :notes
      t.string :qr_token, null: false
      t.string :time_zone, null: false, default: "UTC"

      t.timestamps
    end

    add_index :pets, :qr_token, unique: true
  end
end
