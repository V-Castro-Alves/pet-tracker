require "test_helper"

class PetInviteMailerTest < ActionMailer::TestCase
  test "invitation includes the acceptance link" do
    invite = pet_invites(:pending)
    email = PetInviteMailer.with(invite: invite).invitation

    assert_equal [ invite.invited_email ], email.to
    assert_match invite.pet.name, email.subject
    acceptance_url = Rails.application.routes.url_helpers.invitation_url(invite.invite_token, host: "example.com")
    assert_match acceptance_url, email.text_part.body.to_s
  end
end
