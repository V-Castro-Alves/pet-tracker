require "test_helper"

class FoodBagsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "starts a replacement bag" do
    assert_difference "FoodBag.count", 1 do
      post pet_food_bags_url(pets(:one)), params: { food_bag: { total_weight_g: 4000, low_stock_percentage: 15, started_at: "2026-08-29T10:00" } }
    end
    assert food_bags(:active).reload.ended_at?
    assert_redirected_to pet_food_bags_url(pets(:one))
  end

  test "cannot view another user's inventory" do
    get pet_food_bags_url(pets(:two))
    assert_response :not_found
  end
end
