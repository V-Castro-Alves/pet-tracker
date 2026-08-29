require "test_helper"

Selenium::WebDriver.logger.level = :warn

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SYSTEM_TEST_DRIVER"] == "rack_test"
    driven_by :rack_test
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  private
    def set_control(selector, value)
      field = find(selector)
      if Capybara.current_driver == :rack_test
        field.set(value)
      else
        execute_script <<~JS, field, value
          arguments[0].value = arguments[1];
          arguments[0].dispatchEvent(new Event("input", { bubbles: true }));
          arguments[0].dispatchEvent(new Event("change", { bubbles: true }));
        JS
      end
    end

    def submit_form(button_text)
      button = find_button(button_text)
      if Capybara.current_driver == :rack_test
        button.click
      else
        execute_script "arguments[0].form.requestSubmit(arguments[0])", button
      end
    end

    def sign_in_as(user, password: "password")
      visit new_session_path
      set_control "#email_address", user.email_address
      set_control "#password", password
      submit_form "Sign in"

      assert_text "Your pets"
    end
end
