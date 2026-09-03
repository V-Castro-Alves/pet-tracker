require "test_helper"

class VaccineNotificationJobTest < ActiveJob::TestCase
  test "publishes due vaccine notifications idempotently" do
    vaccine = vaccines(:overdue)
    key = "vaccine:#{vaccine.id}:overdue:#{vaccine.next_due_date.iso8601}"

    assert_difference -> { notifications_for(key).count }, 1 do
      VaccineNotificationJob.perform_now(on: Date.new(2026, 9, 1))
    end
    assert_no_difference -> { notifications_for(key).count } do
      VaccineNotificationJob.perform_now(on: Date.new(2026, 9, 1))
    end
  end

  private
    def notifications_for(key)
      Notification.where(user: users(:one), deduplication_key: key)
    end
end
