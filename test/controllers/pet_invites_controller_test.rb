require "test_helper"

class PetInvitesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { sign_in_as users(:one) }

  test "administrator creates and emails a targeted invitation" do
    assert_enqueued_emails 1 do
      assert_difference "PetInvite.count", 1 do
        post pet_pet_invites_url(pets(:one)), params: { pet_invite: { invited_email: "new@example.com" } }
      end
    end

    invite = PetInvite.find_by!(invited_email: "new@example.com")
    assert_equal users(:one), invite.created_by
    assert_in_delta 7.days.from_now, invite.expires_at, 2.seconds
  end

  test "administrator creates a shareable invitation without email" do
    assert_no_enqueued_emails do
      post pet_pet_invites_url(pets(:one)), params: { pet_invite: { invited_email: "" } }
    end
    assert_redirected_to pet_pet_users_url(pets(:one))
  end

  test "non-administrator cannot create invitations" do
    PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current)
    sign_out
    sign_in_as users(:two)

    assert_no_difference "PetInvite.count" do
      post pet_pet_invites_url(pets(:one)), params: { pet_invite: { invited_email: "new@example.com" } }
    end
    assert_redirected_to pet_pet_users_url(pets(:one))
  end
end
