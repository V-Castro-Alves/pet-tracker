require "application_system_test_case"

class QrMealLogsTest < ApplicationSystemTestCase
  test "meal QR code is large enough to scan" do
    sign_in_as users(:one)
    visit pet_qr_code_path(pets(:one))

    rendered_width = page.evaluate_script("document.querySelector('.qr-image svg').getBoundingClientRect().width")
    assert_operator rendered_width, :>=, 400
  end

  test "guest signs in from a QR code and reaches feeding history" do
    pet = pets(:one)
    user = users(:one)

    visit qr_meal_log_path(qr_token: pet.qr_token)
    assert_text "Sign in"

    set_control "#email_address", user.email_address
    set_control "#password", "password"
    submit_form "Sign in"

    assert_text "#{pet.name}'s feedings"
    assert_field "Amount (grams)"
  end
end
