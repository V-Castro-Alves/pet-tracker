require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new registration is public" do
    get new_registration_url
    assert_response :success
  end

  test "creates a user and signs them in" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_url, params: {
        user: {
          name: "Taylor",
          email_address: "TAYLOR@example.com ",
          time_zone: "Brasilia",
          password: "secret-password",
          password_confirmation: "secret-password"
        }
      }
    end

    assert_redirected_to root_url
    assert User.exists?(email_address: "taylor@example.com")
  end

  test "rejects invalid registration" do
    assert_no_difference "User.count" do
      post registration_url, params: { user: { name: "", email_address: "bad", time_zone: "Nowhere" } }
    end

    assert_response :unprocessable_entity
  end
end
