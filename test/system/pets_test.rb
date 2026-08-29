require "application_system_test_case"

class PetsTest < ApplicationSystemTestCase
  test "user adds a pet and its first scheduled meal" do
    sign_in_as users(:one)
    click_link "Add pet"

    fill_in "pet_name", with: "Milo"
    fill_in "pet_species", with: "Cat"
    fill_in "pet_breed", with: "Tabby"
    select "(GMT+00:00) UTC", from: "pet_time_zone"

    assert_field "pet_name", with: "Milo"
    assert_field "pet_species", with: "Cat"
    assert_field "pet_breed", with: "Tabby"

    assert_difference [ "Pet.count", "PetUser.count" ], 1 do
      click_button "Create Pet"
      assert_text "Milo was added. Now set up a feeding schedule."
    end

    click_link "Add meal"
    fill_in "Meal name", with: "Supper"
    fill_in "Daily time", with: "19:30"
    fill_in "Default serving (grams)", with: "85"

    assert_difference "MealSlot.count", 1 do
      click_button "Create Meal slot"
      assert_text "Supper was added."
    end

    assert_text "19:30"
    assert_text "85 g default serving"
  end
end