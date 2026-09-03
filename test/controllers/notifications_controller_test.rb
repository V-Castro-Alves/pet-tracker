require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "lists only the current user's notifications" do
    Notification.create!(user: users(:two), kind: "food_low", title: "Private", body: "Private", path: "/", deduplication_key: "private")
    get notifications_url
    assert_response :success
    assert_select "h2", text: notifications(:unread_food).title
    assert_not_includes response.body, "Private"
  end

  test "marks a notification read and follows its path" do
    patch notification_url(notifications(:unread_food))
    assert notifications(:unread_food).reload.read?
    assert_redirected_to notifications(:unread_food).path
  end

  test "cannot mark another user's notification read" do
    other = Notification.create!(user: users(:two), kind: "food_low", title: "Private", body: "Private", path: "/", deduplication_key: "private")
    patch notification_url(other)
    assert_response :not_found
  end
end
