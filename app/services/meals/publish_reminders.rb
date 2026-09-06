module Meals
  class PublishReminders
    def initialize(pet, now: Time.current)
      @pet = pet
      @now = now
    end

    def call
      finder = OccurrenceFinder.new(pet, now: now)
      local_date = now.in_time_zone(pet.time_zone).to_date
      pet.meal_slots.active.includes(:meal_reminder_preferences).find_each do |slot|
        ((local_date - 2.days)..local_date).each do |date|
          next unless finder.occurs_on?(slot, date)

          occurrence = finder.for(slot: slot, date: date)
          next if occurrence.scheduled_for > now || occurrence.scheduled_for < now - 2.days
          next if pet.meal_logs.exists?(meal_slot: slot, scheduled_for: occurrence.scheduled_for)

          recipient_ids = pet.users.filter_map do |user|
            preference = slot.meal_reminder_preferences.find { |setting| setting.user_id == user.id }
            next if preference && !preference.enabled?
            due_at = occurrence.scheduled_for + (preference&.delay_minutes || 60).minutes
            user.id if due_at <= now && due_at >= now - 1.day
          end
          Notifications::Publish.new(
            pet: pet, recipients: pet.users.where(id: recipient_ids),
            kind: "meal_unresolved", title: "Was #{pet.name} fed?",
            body: "#{slot.name} at #{I18n.l(occurrence.scheduled_for.in_time_zone(pet.time_zone), format: :short)} has not been logged.",
            path: Rails.application.routes.url_helpers.new_pet_meal_log_path(pet, meal_slot_id: slot.id, date: date.iso8601),
            deduplication_key: "meal:#{slot.id}:#{occurrence.scheduled_for.to_i}"
          ).call
        end
      end
    end

    private
      attr_reader :pet, :now
  end
end
