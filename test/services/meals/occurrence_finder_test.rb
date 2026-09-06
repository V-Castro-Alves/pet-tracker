require "test_helper"

class Meals::OccurrenceFinderTest < ActiveSupport::TestCase
  test "builds occurrences in the pet's time zone" do
    pets(:one).update!(time_zone: "Brasilia")
    now = Time.utc(2026, 8, 29, 12, 0)
    occurrence = Meals::OccurrenceFinder.new(pets(:one), now: now).for(slot: meal_slots(:breakfast), date: Date.new(2026, 8, 29))
    assert_equal "2026-08-29 08:00:00 -0300", occurrence.scheduled_for.to_s
  end

  test "does not treat dates before a meal was created as unresolved" do
    pet = pets(:one)
    pet.update!(time_zone: "Brasilia")
    slot = meal_slots(:breakfast)
    slot.update_column(:created_at, Time.utc(2026, 9, 5, 23, 30))
    now = Time.utc(2026, 9, 6, 16)

    unresolved = Meals::OccurrenceFinder.new(pet, now: now).unresolved

    assert_equal [ Date.new(2026, 9, 5), Date.new(2026, 9, 6) ], unresolved.filter_map { |occurrence|
      occurrence.scheduled_for.in_time_zone(pet.time_zone).to_date if occurrence.meal_slot == slot
    }
  end
end
