class MealNotificationJob < ApplicationJob
  queue_as :background

  def perform(now: Time.current)
    Pet.where(household_id: nil).find_each do |pet|
      Meals::PublishReminders.new(pet, now: now).call
    end
  end
end
