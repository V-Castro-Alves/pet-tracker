class CreateMealSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_slots do |t|
      t.references :pet, null: false, foreign_key: true
      t.string :name, null: false
      t.time :scheduled_time, null: false
      t.decimal :default_amount_g, precision: 8, scale: 2, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :meal_slots, %i[pet_id scheduled_time], unique: true, where: "active = 1", name: :index_active_meal_slots_on_pet_and_time
  end
end
