require "application_system_test_case"

class PetsTest < ApplicationSystemTestCase
  test "user adds a pet to an enabled household and creates a care task" do
    sign_in_as users(:one)
    visit new_pet_path(household_id: households(:one).public_id)

    set_control "#pet_name", "Milo"
    set_control "#pet_species", "Cat"
    set_control "#pet_breed", "Tabby"
    attach_file "Pet photo", Rails.root.join("public/icon.png")
    assert_field "pet_name", with: "Milo"
    assert_field "pet_species", with: "Cat"
    assert_field "pet_breed", with: "Tabby"
    assert_no_field "Time zone"
    assert_selector ".photo-preview img", visible: true

    submit_form "Create Pet"
    assert_text "Milo was added to Pet Care."

    visit new_household_task_path(households(:one))
    set_control "#task_title", "Milo's supper"
    select "Pet care", from: "Task type"
    select "Milo", from: "Pet"
    select "Feeding", from: "Care type"
    set_control "#task_amount_g", "85"
    submit_form "Create Task"
    assert_text "Milo's supper"
  end
end
