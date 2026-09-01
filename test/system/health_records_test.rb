require "application_system_test_case"

class HealthRecordsTest < ApplicationSystemTestCase
  test "caretaker adds a medical-history entry" do
    pet = pets(:one)
    sign_in_as users(:one)
    visit new_pet_medical_entry_path(pet)

    set_control "#medical_entry_entry_date", "2026-08-20"
    set_control "#medical_entry_title", "Ear check"
    set_control "#medical_entry_body", "No infection found. Continue routine cleaning."
    submit_form "Create Medical entry"

    assert_text "Medical entry added."
    assert_text "Ear check"
    assert_text "No infection found. Continue routine cleaning."
    assert_text "Added by #{users(:one).name}"
  end
end
