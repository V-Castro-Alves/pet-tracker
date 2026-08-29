require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "visitor creates an account" do
    visit new_registration_path

    fill_in "Name", with: "Taylor"
    fill_in "Email", with: "taylor@example.com"
    select "(GMT+00:00) UTC", from: "Time zone"
    fill_in "Password", with: "secret-password"
    fill_in "Password confirmation", with: "secret-password"

    assert_difference "User.count", 1 do
      click_button "Create account"
      assert_text "Welcome to Pet Tracker!"
    end

    assert_text "Add your first pet"
    assert_button "Sign out"
  end
end
