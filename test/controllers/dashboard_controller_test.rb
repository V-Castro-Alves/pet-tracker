require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get root_url
    assert_redirected_to new_session_url
  end

  test "shows personal reminders with exact occurrence links and quiet pet management" do
    travel_to Time.utc(2026, 9, 26, 12) do
      MealLog.delete_all
      MealSlot.update_all(created_at: Time.current.beginning_of_day)
      sign_in_as users(:one)
      get root_url
      assert_response :success
      assert_select "h1", "A little care for today."
      assert_select "h2", "Needs attention"
      assert_select "h2", "Later today"
      assert_select ".reminder-card", count: 2
      assert_select ".reminder-copy .eyebrow", text: "Luna", count: 0
      assert_select "a[href=?]", new_pet_meal_log_path(pets(:one), meal_slot_id: meal_slots(:breakfast).id, date: "2026-09-26")
      assert_select "a[href=?]", new_pet_path, count: 0
      assert_select "nav a[href=?]", pets_path
    end
  end

  test "new users get a single onboarding action" do
    PetUser.where(user: users(:one)).delete_all
    sign_in_as users(:one)
    get root_url
    assert_select "h2", "Add your first pet"
    assert_select "a[href=?]", new_pet_path, count: 1
    assert_select ".reminder-card", count: 0
  end

  test "empty reminders offer routines without claiming all meals were logged" do
    pets(:one).meal_slots.update_all(active: false)
    sign_in_as users(:one)
    get root_url
    assert_select ".care-clear", text: /No meal reminders need attention/
    assert_select "a[href=?]", pets_path, text: "View your pets & manage routines"
  end
end
