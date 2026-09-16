require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "creation broadcasts only to the recipient and read changes update all targets" do
    stream = "#{users(:one).to_gid_param}:notifications"
    other_stream = "#{users(:two).to_gid_param}:notifications"
    assert_no_broadcasts(other_stream) do
      assert_broadcasts(stream, 3) do
        Notification.create!(user: users(:one), kind: "meal_unresolved", title: "Meal due",
          body: "Dinner has not been logged", path: "/notifications", deduplication_key: "live-test")
      end
    end
    assert_broadcasts(stream, 3) do
      notifications(:unread_food).update!(read_at: Time.current)
    end
    assert_no_broadcasts(stream) do
      notifications(:unread_food).update!(delivered_at: Time.current)
    end
  end
end
