require "test_helper"

class MealRemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pet = pets(:one)
    @slot = meal_slots(:breakfast)
    @pet.pet_users.create!(user: users(:two), linked_at: Time.current)
    sign_in_as users(:two)
  end

  test "caretakers can update only their own weekday preferences" do
    other = @slot.meal_reminder_preferences.create!(user: users(:one), delay_minutes: 15)
    get edit_pet_meal_slot_reminder_url(@pet, @slot)
    assert_response :success
    patch pet_meal_slot_reminder_url(@pet, @slot), params: {
      reminder_preference: { user_id: users(:one).id, weekdays: {
        "1" => { timing: "0" }, "6" => { timing: "30" }, "0" => { timing: "custom", minutes: "45" }, "2" => { timing: "off" }
      } }, meal_slot: { name: "Changed" }
    }
    assert_redirected_to pet_meal_slots_url(@pet)
    mine = @slot.meal_reminder_preferences.find_by!(user: users(:two))
    assert_equal({ "1" => 0, "6" => 30, "0" => 45, "2" => nil }, mine.weekday_delays)
    assert_equal({}, other.reload.weekday_delays)
    assert_equal "Breakfast", @slot.reload.name
  end

  test "invalid custom delays render errors without persisting" do
    [ "-1", "1441", "1.5", "" ].each do |minutes|
      patch pet_meal_slot_reminder_url(@pet, @slot), params: {
        reminder_preference: { weekdays: { "1" => { timing: "custom", minutes: minutes } } }
      }
      assert_response :unprocessable_entity
      assert_nil @slot.meal_reminder_preferences.find_by(user: users(:two))
    end
  end

  test "cannot access an unlinked pet or a slot belonging to another pet" do
    sign_in_as users(:one)
    get edit_pet_meal_slot_reminder_url(pets(:two), meal_slots(:other_pet_breakfast))
    assert_response :not_found
    patch pet_meal_slot_reminder_url(@pet, meal_slots(:other_pet_breakfast)), params: { reminder_preference: { weekdays: { "1" => { timing: "0" } } } }
    assert_response :not_found
  end
end
