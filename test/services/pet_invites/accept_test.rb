require "test_helper"

class PetInvites::AcceptTest < ActiveSupport::TestCase
  test "accepts a shareable invitation once" do
    invite = pet_invites(:shareable)

    assert_difference "PetUser.count", 1 do
      pet = PetInvites::Accept.new(invite: invite, user: users(:two)).call
      assert_equal pets(:one), pet
    end

    assert_equal users(:two), invite.reload.accepted_by
    assert invite.accepted_at?
  end

  test "repeated acceptance by the same user is idempotent" do
    invite = pet_invites(:shareable)
    service = PetInvites::Accept.new(invite: invite, user: users(:two))
    service.call

    assert_no_difference "PetUser.count" do
      assert_equal pets(:one), service.call
    end
  end

  test "rejects an expired invitation" do
    assert_raises PetInvites::Accept::UnavailableError do
      PetInvites::Accept.new(invite: pet_invites(:expired), user: users(:two)).call
    end
  end

  test "targeted invitations require the matching account" do
    assert_raises PetInvites::Accept::EmailMismatchError do
      PetInvites::Accept.new(invite: pet_invites(:pending), user: users(:two)).call
    end
  end
end
