class CreateMealLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_logs do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :meal_slot, null: false, foreign_key: true
      t.datetime :scheduled_for, null: false
      t.string :status, null: false
      t.decimal :actual_amount_g, precision: 8, scale: 2
      t.datetime :actual_time
      t.references :logged_by_user, null: false, foreign_key: { to_table: :users }
      t.references :duplicate_of, foreign_key: { to_table: :meal_logs }

      t.timestamps
    end

    add_index :meal_logs, %i[meal_slot_id scheduled_for]
  end
end
