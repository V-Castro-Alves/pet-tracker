require "test_helper"

class FoodBagTest < ActiveSupport::TestCase
  test "detects low stock from the configured percentage" do
    bag = food_bags(:active)
    bag.remaining_weight_g = 450
    assert bag.low_stock?
    bag.remaining_weight_g = 451
    assert_not bag.low_stock?
  end

  test "percentage remaining is clamped for inventory discrepancies" do
    bag = food_bags(:active)
    bag.remaining_weight_g = -10
    assert_equal 0, bag.percentage_remaining
  end
end
