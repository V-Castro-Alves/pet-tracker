require "test_helper"

class MedicalEntryTest < ActiveSupport::TestCase
  test "requires details and author" do
    entry = pets(:one).medical_entries.new(entry_date: Date.new(2026, 8, 1), body: "")
    assert_not entry.valid?
    assert entry.errors.added?(:body, :blank)
  end

  test "rejects future entries" do
    entry = pets(:one).medical_entries.new(entry_date: Date.current + 1, body: "Future", created_by: users(:one))
    assert_not entry.valid?
  end
end
