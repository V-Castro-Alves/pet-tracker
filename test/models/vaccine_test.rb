require "test_helper"

class VaccineTest < ActiveSupport::TestCase
  test "classifies overdue, due soon, current, and one-time vaccines" do
    vaccine = vaccines(:overdue)
    assert_equal :overdue, vaccine.due_status(on: Date.new(2026, 8, 2))
    assert_equal :due_soon, vaccine.due_status(on: Date.new(2026, 7, 26))
    assert_equal :current, vaccine.due_status(on: Date.new(2026, 7, 1))
    assert_equal :none, vaccines(:one_time).due_status(on: Date.new(2026, 8, 2))
  end

  test "next due date cannot precede date given" do
    vaccine = pets(:one).vaccines.new(name: "Test", date_given: Date.new(2026, 8, 1), next_due_date: Date.new(2026, 7, 1))
    assert_not vaccine.valid?
  end
end
