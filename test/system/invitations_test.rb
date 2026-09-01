require "application_system_test_case"

class InvitationsTest < ApplicationSystemTestCase
  test "existing user signs in from an invitation and joins the pet" do
    invite = pet_invites(:shareable)
    user = users(:two)

    visit invitation_path(invite.invite_token)
    assert_text "Sign in"

    set_control "#email_address", user.email_address
    set_control "#password", "password"
    submit_form "Sign in"

    assert_text "Join #{invite.pet.name}'s care team"
    click_button "Join #{invite.pet.name}'s team"

    assert_text "You now help care for #{invite.pet.name}."
    assert_selector "h1", text: invite.pet.name, exact_text: true
  end
end
