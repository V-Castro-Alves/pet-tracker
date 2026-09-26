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
  test "caretakers can view but cannot change the schedule" do
    pet = pets(:one)
    slot = meal_slots(:breakfast)
    pet.pet_users.create!(user: users(:two), linked_at: Time.current)
    sign_in_as users(:two)
    get pet_meal_slots_url(pet)
    assert_response :success
    assert_select "a", text: "My reminders"
    assert_select "a", text: "Add meal", count: 0
    get new_pet_meal_slot_url(pet)
    assert_response :forbidden
    get edit_pet_meal_slot_url(pet, slot)
    assert_response :forbidden
    assert_no_difference "MealSlot.count" do
      post pet_meal_slots_url(pet), params: { meal_slot: { name: "Lunch", scheduled_time: "12:00", default_amount_g: 75 } }
    end
    assert_response :forbidden
    patch pet_meal_slot_url(pet, slot), params: { meal_slot: { name: "Changed" } }
    assert_response :forbidden
    delete pet_meal_slot_url(pet, slot)
    assert_response :forbidden
    assert_equal "Breakfast", slot.reload.name
    assert slot.active?
  end
end
