require "application_system_test_case"

class MealLogsTest < ApplicationSystemTestCase
  test "user logs a scheduled meal" do
    user = users(:one)
    pet = pets(:one)
    dinner = meal_slots(:dinner)

    sign_in_as user
    click_link pet.name
    visit new_pet_meal_log_path(pet, meal_slot_id: dinner.id, date: Date.current.iso8601)

    assert_text "Log Dinner"
    select "Fed", from: "Status"
    fill_in "Amount (grams)", with: "125"

    assert_difference "MealLog.count", 1 do
      click_button "Save meal"
      assert_text "Dinner was logged."
    end

    assert_text "Meal history"
    assert_text "Dinner"
    assert_text "125 g"
    assert_text "by #{user.name}"
  end
end
