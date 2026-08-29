require "test_helper"

class MealSlotTest < ActiveSupport::TestCase
  test "requires a positive serving" do
    slot = pets(:one).meal_slots.new(name: "Lunch", scheduled_time: "12:00", default_amount_g: 0)
    assert_not slot.valid?
  end

  test "prevents two active meals at the same time for a pet" do
    slot = pets(:one).meal_slots.new(name: "Second breakfast", scheduled_time: "08:00", default_amount_g: 50)
    assert_not slot.valid?
    assert slot.errors.added?(:scheduled_time, :taken, value: slot.scheduled_time)
  end

  test "allows a time used only by an inactive meal" do
    meal_slots(:breakfast).update!(active: false)
    slot = pets(:one).meal_slots.new(name: "New breakfast", scheduled_time: "08:00", default_amount_g: 90)
    assert slot.valid?
  end
end
