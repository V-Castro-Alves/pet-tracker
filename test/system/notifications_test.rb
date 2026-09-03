require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  test "user sees and opens an unread notification" do
    sign_in_as users(:one)
    visit notifications_path

    assert_text notifications(:unread_food).title
    click_button "Read and open"

    assert_current_path notifications(:unread_food).path
    assert notifications(:unread_food).reload.read?
  end
end
