require "test_helper"

class QrMealLogsControllerTest < ActionDispatch::IntegrationTest
  test "guests sign in and return to the QR destination" do
    get qr_meal_log_url(qr_token: pets(:one).qr_token)
    assert_redirected_to new_session_url

    post session_url, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to qr_meal_log_url(qr_token: pets(:one).qr_token)
  end

  test "linked users continue to the meal form" do
    sign_in_as users(:one)
    get qr_meal_log_url(qr_token: pets(:one).qr_token)

    assert_redirected_to new_pet_meal_log_url(pets(:one), source: "qr")
  end

  test "unlinked users receive a forbidden response" do
    sign_in_as users(:two)
    get qr_meal_log_url(qr_token: pets(:one).qr_token)

    assert_response :forbidden
    assert_select "h1", "You do not have access to this pet"
  end

  test "unknown tokens are not found" do
    sign_in_as users(:one)
    get qr_meal_log_url(qr_token: "unknown-token")
    assert_response :not_found
  end
end
