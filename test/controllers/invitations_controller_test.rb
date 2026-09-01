require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "guest returns to invitation after signing in" do
    invite = pet_invites(:shareable)
    get invitation_url(invite.invite_token)
    assert_redirected_to new_session_url

    post session_url, params: { email_address: users(:two).email_address, password: "password" }
    assert_redirected_to invitation_url(invite.invite_token)
  end

  test "accepts an invitation" do
    sign_in_as users(:two)
    assert_difference "PetUser.count", 1 do
      post invitation_url(pet_invites(:shareable).invite_token)
    end
    assert_redirected_to pet_url(pets(:one))
  end

  test "expired invitation cannot be accepted" do
    sign_in_as users(:two)
    assert_no_difference "PetUser.count" do
      post invitation_url(pet_invites(:expired).invite_token)
    end
    assert_redirected_to invitation_url(pet_invites(:expired).invite_token)
  end
end
