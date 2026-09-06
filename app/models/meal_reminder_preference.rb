class MealReminderPreference < ApplicationRecord
  belongs_to :meal_slot
  belongs_to :user

  validates :user_id, uniqueness: { scope: :meal_slot_id }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :delay_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
end
