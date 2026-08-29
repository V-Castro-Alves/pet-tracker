require "test_helper"

class PetTest < ActiveSupport::TestCase
  test "requires core profile fields" do
    pet = Pet.new
    assert_not pet.valid?
    assert pet.errors.added?(:name, :blank)
    assert pet.errors.added?(:species, :blank)
  end

  test "rejects a future birthdate" do
    pet = pets(:one)
    pet.birthdate = Date.current.tomorrow
    assert_not pet.valid?
  end
end
