require "test_helper"

class Meals::LogMealTest < ActiveSupport::TestCase
  test "rejects a normal duplicate and permits an explicit duplicate" do
    existing = meal_logs(:breakfast_today)
    attributes = { scheduled_for: existing.scheduled_for, status: "fed", actual_amount_g: 90, actual_time: Time.current }
    service_args = { pet: pets(:one), meal_slot: meal_slots(:breakfast), user: users(:one), attributes: attributes }

    assert_raises(Meals::LogMeal::DuplicateMealError) { Meals::LogMeal.new(**service_args).call }
    duplicate = Meals::LogMeal.new(**service_args, allow_duplicate: true).call
    assert_equal existing, duplicate.duplicate_of
  end
end
