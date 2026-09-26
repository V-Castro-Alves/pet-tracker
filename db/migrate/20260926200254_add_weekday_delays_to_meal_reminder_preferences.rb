class AddWeekdayDelaysToMealReminderPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :meal_reminder_preferences, :weekday_delays, :json, default: {}, null: false
  end
end
