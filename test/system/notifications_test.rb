require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  test "user sees and opens an unread notification" do
    sign_in_as users(:one)
    visit notifications_path

    assert_text notifications(:unread_food).title
    submit_form "Read and open"

    assert_current_path notifications(:unread_food).path
    assert notifications(:unread_food).reload.read?
  end
  test "caretaker changes their meal reminder" do
    sign_in_as users(:one)
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    set_control "#reminder_preference_delay_minutes", "5"
    submit_form "Update Meal slot"
    assert_text "Breakfast was updated."
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    assert_field "Grace window (minutes after meal time)", with: "5"
    select "No reminders for this meal", from: "Remind me if this meal has not been logged"
    submit_form "Update Meal slot"
    assert_text "Breakfast was updated."
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    assert_select "Remind me if this meal has not been logged", selected: "No reminders for this meal"
  end
end
