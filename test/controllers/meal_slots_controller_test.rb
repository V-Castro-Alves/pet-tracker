require "test_helper"

class MealSlotsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "creates a meal slot for an owned pet" do
    assert_difference "MealSlot.count", 1 do
      post pet_meal_slots_url(pets(:one)), params: { meal_slot: { name: "Lunch", scheduled_time: "12:00", default_amount_g: 75 } }
    end
    assert_redirected_to pet_meal_slots_url(pets(:one))
  end

  test "soft disables a meal instead of deleting it" do
    assert_no_difference "MealSlot.count" do
      delete pet_meal_slot_url(pets(:one), meal_slots(:breakfast))
    end
    assert_not meal_slots(:breakfast).reload.active?
  end

  test "cannot manage another user's schedule" do
    get pet_meal_slots_url(pets(:two))
    assert_response :not_found
  end
  test "saves only the signed in user's preference" do
    pet = pets(:one)
    slot = meal_slots(:breakfast)
    other = slot.meal_reminder_preferences.create!(user: users(:two), delay_minutes: 30)
    patch pet_meal_slot_url(pet, slot), params: {
      meal_slot: { name: slot.name },
      reminder_preference: { enabled: "0", delay_minutes: 5, user_id: users(:two).id }
    }
    assert_redirected_to pet_meal_slots_url(pet)
    mine = slot.meal_reminder_preferences.find_by!(user: users(:one))
    assert_not mine.enabled?
    assert_equal 5, mine.delay_minutes
    assert_equal 30, other.reload.delay_minutes
    assert other.enabled?
  end

  test "invalid reminder rolls back meal changes and displays errors" do
    slot = meal_slots(:breakfast)
    original_name = slot.name
    patch pet_meal_slot_url(pets(:one), slot), params: {
      meal_slot: { name: "Changed" }, reminder_preference: { delay_minutes: -1 }
    }
    assert_response :unprocessable_entity
    assert_equal original_name, slot.reload.name
    assert_select ".field_with_errors"
  end

  test "creates meal with personal reminder and rejects unauthorized edits" do
    post pet_meal_slots_url(pets(:one)), params: {
      meal_slot: { name: "Lunch", scheduled_time: "12:00", default_amount_g: 75 },
      reminder_preference: { enabled: "1", delay_minutes: 5 }
    }
    assert_equal 5, pets(:one).meal_slots.find_by!(name: "Lunch").meal_reminder_preferences.find_by!(user: users(:one)).delay_minutes
    patch pet_meal_slot_url(pets(:two), meal_slots(:other_pet_breakfast)), params: {
      meal_slot: { name: "Changed" }, reminder_preference: { delay_minutes: 5 }
    }
    assert_response :not_found
  end
end
