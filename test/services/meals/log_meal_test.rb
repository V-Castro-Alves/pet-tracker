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

  test "a fed meal consumes the active bag in the same transaction" do
    attributes = { scheduled_for: 1.day.from_now, status: "fed", actual_amount_g: 125, actual_time: Time.current }
    assert_difference -> { food_bags(:active).reload.remaining_weight_g }, -125 do
      Meals::LogMeal.new(pet: pets(:one), meal_slot: meal_slots(:dinner), user: users(:one), attributes: attributes).call
    end
  end

  test "a skipped meal does not consume food" do
    attributes = { scheduled_for: 2.days.from_now, status: "skipped", actual_amount_g: nil, actual_time: nil }
    assert_no_changes -> { food_bags(:active).reload.remaining_weight_g } do
      Meals::LogMeal.new(pet: pets(:one), meal_slot: meal_slots(:dinner), user: users(:one), attributes: attributes).call
    end
  end

  test "crossing the low-stock threshold publishes one alert" do
    food_bags(:active).update!(remaining_weight_g: 500)
    attributes = { scheduled_for: 4.days.from_now, status: "fed", actual_amount_g: 100, actual_time: Time.current }

    assert_difference -> { Notification.where(kind: "food_low", pet: pets(:one)).count }, 1 do
      Meals::LogMeal.new(pet: pets(:one), meal_slot: meal_slots(:dinner), user: users(:one), attributes: attributes).call
    end
    assert food_bags(:active).reload.low_stock_notified_at?
  end
end
