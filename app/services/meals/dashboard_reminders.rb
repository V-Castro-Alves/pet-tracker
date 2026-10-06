module Meals
  class DashboardReminders
    Reminder = Data.define(:pet, :meal_slot, :scheduled_for, :due_at)

    def initialize(user, now: Time.current)
      @user = user
      @now = now
    end

    def call
      user.pets.where(household_id: nil).with_attached_photo.includes(meal_slots: :meal_reminder_preferences).flat_map do |pet|
        reminders_for(pet)
      end.sort_by { |reminder| [ reminder.due_at, reminder.pet.name, reminder.meal_slot.id ] }
    end

    private
      attr_reader :user, :now

      def reminders_for(pet)
        finder = OccurrenceFinder.new(pet, now: now)
        finish = now.in_time_zone(user.time_zone).end_of_day
        start = now - 2.days
        dates = start.in_time_zone(pet.time_zone).to_date..finish.in_time_zone(pet.time_zone).to_date
        resolved = pet.meal_logs.where(scheduled_for: start..finish).pluck(:meal_slot_id, :scheduled_for).to_set

        pet.meal_slots.select(&:active?).flat_map do |slot|
          preference = slot.meal_reminder_preferences.find { |setting| setting.user_id == user.id }
          dates.filter_map do |date|
            next unless finder.occurs_on?(slot, date)
            delay = preference ? preference.delay_for(date) : 60
            next if delay.nil?

            occurrence = finder.for(slot: slot, date: date)
            due_at = occurrence.scheduled_for + delay.minutes
            # Match the publisher's recent-reminder window, with today's upcoming reminders too.
            next if occurrence.scheduled_for < start || due_at < now - 1.day || due_at > finish
            next if resolved.include?([ slot.id, occurrence.scheduled_for ])

            Reminder.new(pet: pet, meal_slot: slot, scheduled_for: occurrence.scheduled_for, due_at: due_at)
          end
        end
      end
  end
end
