class MealNotificationJob < ApplicationJob
  queue_as :background

  def perform(now: Time.current)
    Pet.find_each do |pet|
      finder = Meals::OccurrenceFinder.new(pet, now: now)
      publish_reminders(pet, finder, now)
      finder.unresolved(lookback: 1.day).each do |occurrence|
        local_time = occurrence.scheduled_for.in_time_zone(pet.time_zone)
        Notifications::Publish.new(
          pet: pet,
          kind: "meal_unresolved",
          title: "Was #{pet.name} fed?",
          body: "#{occurrence.meal_slot.name} at #{I18n.l(local_time, format: :short)} is still unresolved.",
          path: Rails.application.routes.url_helpers.new_pet_meal_log_path(pet, meal_slot_id: occurrence.meal_slot.id, date: local_time.to_date.iso8601),
          deduplication_key: "meal:#{occurrence.meal_slot.id}:#{occurrence.scheduled_for.to_i}"
        ).call
      end
    end
  end

  private
    def publish_reminders(pet, finder, now)
      local_date = now.in_time_zone(pet.time_zone).to_date
      pet.meal_slots.active.find_each do |slot|
        occurrence = finder.for(slot: slot, date: local_date)
        next unless occurrence.scheduled_for.between?(now - 10.minutes, now)
        next if pet.meal_logs.exists?(meal_slot: slot, scheduled_for: occurrence.scheduled_for)

        Notifications::Publish.new(
          pet: pet,
          kind: "meal_reminder",
          title: "Time for #{pet.name}'s #{slot.name.downcase}",
          body: "The scheduled serving is #{slot.default_amount_g.to_i} g.",
          path: Rails.application.routes.url_helpers.new_pet_meal_log_path(pet, meal_slot_id: slot.id, date: local_date.iso8601),
          deduplication_key: "meal_reminder:#{slot.id}:#{occurrence.scheduled_for.to_i}"
        ).call
      end
    end
end
