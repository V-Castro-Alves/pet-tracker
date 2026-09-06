class MealNotificationJob < ApplicationJob
  queue_as :background

  def perform(now: Time.current)
    Pet.find_each do |pet|
      Meals::PublishReminders.new(pet, now: now).call
    end
  end
end
