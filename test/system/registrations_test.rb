require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "visitor creates an account" do
    visit new_registration_path

    set_control "#user_name", "Taylor"
    set_control "#user_email_address", "taylor@example.com"
    set_control "#user_password", "secret-password"
    set_control "#user_password_confirmation", "secret-password"
    assert_no_field "Time zone"

    submit_form "Create account"
    assert_text "Welcome to Household!"

    assert_text "Create your first household"
    assert_button "Sign out"
  end
end
