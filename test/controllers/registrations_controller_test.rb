require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new registration is public" do
    get new_registration_url
    assert_response :success
    assert_select "select#user_time_zone", count: 0
    assert_select "input#user_browser_time_zone[type=hidden]", count: 1
  end

  test "creates a user and signs them in" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_url, params: {
        user: {
          name: "Taylor",
          email_address: "TAYLOR@example.com ",
          browser_time_zone: "America/Sao_Paulo",
          password: "secret-password",
          password_confirmation: "secret-password"
        }
      }
    end

    assert_redirected_to root_url
    assert User.exists?(email_address: "taylor@example.com", time_zone: "Brasilia")
  end

  test "rejects invalid registration" do
    assert_no_difference "User.count" do
      post registration_url, params: { user: { name: "", email_address: "bad", browser_time_zone: "Nowhere" } }
    end

    assert_response :unprocessable_entity
  end

  test "returns a new account to the protected destination" do
    get invitation_url(pet_invites(:shareable).invite_token)

    post registration_url, params: {
      user: {
        name: "Guest",
        email_address: "guest@example.com",
        browser_time_zone: "America/Sao_Paulo",
        password: "secret-password",
        password_confirmation: "secret-password"
      }
    }

    assert_redirected_to invitation_url(pet_invites(:shareable).invite_token)
  end

  test "ignores a stale non-invitation destination after registration" do
    get pet_url(pets(:one))
    assert_redirected_to new_session_url

    post registration_url, params: {
      user: {
        name: "New caretaker",
        email_address: "new-caretaker@example.com",
        browser_time_zone: "America/Sao_Paulo",
        password: "secret-password",
        password_confirmation: "secret-password"
      }
    }

    assert_redirected_to root_url
  end
end
