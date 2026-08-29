require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SYSTEM_TEST_DRIVER"] == "rack_test"
    driven_by :rack_test
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  private
    def sign_in_as(user, password: "password")
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: password
      click_button "Sign in"

      assert_text "Your pets"
    end
end
