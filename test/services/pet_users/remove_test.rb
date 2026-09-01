require "test_helper"

class PetUsers::RemoveTest < ActiveSupport::TestCase
  test "administrator can remove another caretaker" do
    membership = PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current)

    assert_difference "PetUser.count", -1 do
      PetUsers::Remove.new(pet: pets(:one), membership: membership, actor: users(:one)).call
    end
  end

  test "caretaker can remove themselves" do
    membership = PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current)
    PetUsers::Remove.new(pet: pets(:one), membership: membership, actor: users(:two)).call
    assert_not PetUser.exists?(membership.id)
  end

  test "cannot remove the last caretaker" do
    assert_raises PetUsers::Remove::LastMemberError do
      PetUsers::Remove.new(pet: pets(:one), membership: pet_users(:owner), actor: users(:one)).call
    end
  end

  test "promotes the oldest remaining caretaker when administrator leaves" do
    replacement = PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current)
    PetUsers::Remove.new(pet: pets(:one), membership: pet_users(:owner), actor: users(:one)).call
    assert replacement.reload.is_pet_admin?
  end
end
