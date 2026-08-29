require "test_helper"

class FoodBags::StartTest < ActiveSupport::TestCase
  test "closes the active bag and starts a full replacement" do
    started_at = Time.current
    new_bag = FoodBags::Start.new(pet: pets(:one), attributes: { total_weight_g: 5000, low_stock_percentage: 20, started_at: started_at }).call

    assert_equal started_at.to_i, food_bags(:active).reload.ended_at.to_i
    assert_equal 5000, new_bag.remaining_weight_g
    assert_equal new_bag, pets(:one).active_food_bag
  end
end
