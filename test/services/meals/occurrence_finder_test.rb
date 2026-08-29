require "test_helper"

class Meals::OccurrenceFinderTest < ActiveSupport::TestCase
  test "builds occurrences in the pet's time zone" do
    pets(:one).update!(time_zone: "Brasilia")
    now = Time.utc(2026, 8, 29, 12, 0)
    occurrence = Meals::OccurrenceFinder.new(pets(:one), now: now).for(slot: meal_slots(:breakfast), date: Date.new(2026, 8, 29))
    assert_equal "2026-08-29 08:00:00 -0300", occurrence.scheduled_for.to_s
  end
end
