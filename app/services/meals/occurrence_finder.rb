module Meals
  class OccurrenceFinder
    GRACE_PERIOD = 60.minutes

    Occurrence = Data.define(:meal_slot, :scheduled_for)

    def initialize(pet, now: Time.current)
      @pet = pet
      @now = now
    end

    def closest
      occurrences_for(local_date - 1.day, local_date, local_date + 1.day)
        .min_by { |occurrence| (occurrence.scheduled_for - now).abs }
    end

    def oldest_unresolved(lookback: 7.days)
      unresolved(lookback: lookback).first
    end

    def unresolved(lookback: 7.days)
      days = (lookback / 1.day).to_i
      dates = ((local_date - days)..local_date).to_a
      occurrences_for(*dates)
        .select { |occurrence| occurrence.scheduled_for + GRACE_PERIOD < now }
        .reject { |occurrence| resolved?(occurrence) }
        .sort_by(&:scheduled_for)
    end

    def for(slot:, date: local_date)
      Occurrence.new(meal_slot: slot, scheduled_for: scheduled_time(slot, date))
    end

    private
      attr_reader :pet, :now

      def local_date
        now.in_time_zone(pet.time_zone).to_date
      end

      def occurrences_for(*dates)
        pet.meal_slots.active.chronological.flat_map do |slot|
          dates.map { |date| self.for(slot: slot, date: date) }
        end
      end

      def scheduled_time(slot, date)
        time = slot.scheduled_time
        Time.use_zone(pet.time_zone) { Time.zone.local(date.year, date.month, date.day, time.hour, time.min, time.sec) }
      end

      def resolved?(occurrence)
        pet.meal_logs.exists?(meal_slot: occurrence.meal_slot, scheduled_for: occurrence.scheduled_for)
      end
  end
end
