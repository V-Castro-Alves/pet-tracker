class CreateMealReminderPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_reminder_preferences do |t|
      t.references :meal_slot, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.integer :delay_minutes, null: false, default: 60
      t.timestamps
    end
    add_index :meal_reminder_preferences, [ :meal_slot_id, :user_id ], unique: true
    add_check_constraint :meal_reminder_preferences, "delay_minutes >= 0 AND delay_minutes <= 1440", name: "meal_reminder_delay_range"
  end
end
