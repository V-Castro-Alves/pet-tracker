require "test_helper"

class MealLogTest < ActiveSupport::TestCase
  test "a skipped meal cannot contain feeding details" do
    log = MealLog.new(pet: pets(:one), meal_slot: meal_slots(:dinner), scheduled_for: Time.current, status: :skipped, actual_amount_g: 20, actual_time: Time.current, logged_by_user: users(:one))
    assert_not log.valid?
  end

  test "meal slot must belong to the pet" do
    log = MealLog.new(pet: pets(:one), meal_slot: meal_slots(:other_pet_breakfast), scheduled_for: Time.current, status: :skipped, logged_by_user: users(:one))
    assert_not log.valid?
  end
end
