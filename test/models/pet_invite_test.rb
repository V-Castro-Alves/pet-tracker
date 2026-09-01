require "test_helper"

class PetInviteTest < ActiveSupport::TestCase
  test "normalizes a targeted email" do
    invite = pets(:one).pet_invites.new(invited_email: " GUEST@Example.COM ", created_by: users(:one), expires_at: 1.day.from_now)
    assert invite.valid?
    assert_equal "guest@example.com", invite.invited_email
  end

  test "reports expiration" do
    assert pet_invites(:expired).expired?
    assert_not pet_invites(:pending).expired?
  end
end
