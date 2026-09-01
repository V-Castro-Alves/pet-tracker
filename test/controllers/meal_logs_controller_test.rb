require "test_helper"

class MealLogsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "logs a scheduled meal" do
    scheduled_for = Time.current.beginning_of_day + 18.hours
    assert_difference "MealLog.count", 1 do
      post pet_meal_logs_url(pets(:one)), params: { meal_log: { meal_slot_id: meal_slots(:dinner).id, scheduled_for: scheduled_for.iso8601, status: "fed", actual_amount_g: 120, actual_time: Time.current.strftime("%Y-%m-%dT%H:%M") } }
    end
    assert_redirected_to pet_meal_logs_url(pets(:one))
  end

  test "QR meal logging returns to the pet dashboard" do
    scheduled_for = 3.days.from_now
    post pet_meal_logs_url(pets(:one)), params: {
      source: "qr",
      meal_log: {
        meal_slot_id: meal_slots(:dinner).id,
        scheduled_for: scheduled_for.iso8601,
        status: "fed",
        actual_amount_g: 120,
        actual_time: Time.current.strftime("%Y-%m-%dT%H:%M")
      }
    }

    assert_redirected_to pet_url(pets(:one))
  end

  test "shows a warning instead of silently logging a duplicate" do
    existing = meal_logs(:breakfast_today)
    assert_no_difference "MealLog.count" do
      post pet_meal_logs_url(pets(:one)), params: { meal_log: { meal_slot_id: existing.meal_slot_id, scheduled_for: existing.scheduled_for.iso8601, status: "fed", actual_amount_g: 100, actual_time: Time.current.strftime("%Y-%m-%dT%H:%M") } }
    end
    assert_response :unprocessable_entity
    assert_select ".duplicate-warning"
  end
end
