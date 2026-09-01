require "test_helper"

class WeightLogsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "creates a weight entry" do
    assert_difference "WeightLog.count", 1 do
      post pet_weight_logs_url(pets(:one)), params: { weight_log: { weight_kg: 13.1, logged_at: "2026-06-01", note: "Morning" } }
    end
    assert_redirected_to pet_weight_logs_url(pets(:one))
  end

  test "updates and deletes an owned entry" do
    patch pet_weight_log_url(pets(:one), weight_logs(:pepper_latest)), params: { weight_log: { weight_kg: 13, logged_at: "2026-08-01" } }
    assert_equal 13, weight_logs(:pepper_latest).reload.weight_kg

    assert_difference "WeightLog.count", -1 do
      delete pet_weight_log_url(pets(:one), weight_logs(:pepper_latest))
    end
  end

  test "cannot access another pet's weight records" do
    get pet_weight_logs_url(pets(:two))
    assert_response :not_found
  end
end
