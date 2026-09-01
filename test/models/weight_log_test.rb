require "test_helper"

class WeightLogTest < ActiveSupport::TestCase
  test "requires a positive weight" do
    log = pets(:one).weight_logs.new(weight_kg: 0, logged_at: Date.new(2026, 6, 1))
    assert_not log.valid?
  end

  test "allows one entry per pet and date" do
    log = pets(:one).weight_logs.new(weight_kg: 13, logged_at: weight_logs(:pepper_latest).logged_at)
    assert_not log.valid?
  end

  test "rejects future entries" do
    log = pets(:one).weight_logs.new(weight_kg: 13, logged_at: Date.current + 1)
    assert_not log.valid?
  end
end
