require "application_system_test_case"

class PetsTest < ApplicationSystemTestCase
  test "user adds a pet and its first scheduled meal" do
    sign_in_as users(:one)
    visit new_pet_path

    set_control "#pet_name", "Milo"
    set_control "#pet_species", "Cat"
    set_control "#pet_breed", "Tabby"
    select "(GMT+00:00) UTC", from: "pet_time_zone"

    assert_field "pet_name", with: "Milo"
    assert_field "pet_species", with: "Cat"
    assert_field "pet_breed", with: "Tabby"

    submit_form "Create Pet"
    assert_text "Milo was added. Now set up a feeding schedule."

    visit new_pet_meal_slot_path(Pet.find_by!(name: "Milo"))
    set_control "#meal_slot_name", "Supper"
    set_control "#meal_slot_scheduled_time", "19:30"
    set_control "#meal_slot_default_amount_g", "85"

    assert_field "meal_slot_scheduled_time", with: "19:30"
    assert_field "meal_slot_default_amount_g", with: "85"

    submit_form "Create Meal slot"
    assert_text "Supper was added."

    assert_text "19:30"
    assert_text "85 g default serving"
  end
end
