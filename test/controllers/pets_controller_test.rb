require "test_helper"

class PetsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "lists only the current user's pets" do
    get pets_url
    assert_response :success
    assert_select "h2", text: "Pepper"
    assert_select "h2", text: "Luna", count: 0
  end

  test "creates a pet and administrator membership together" do
    assert_difference [ "Pet.count", "PetUser.count" ], 1 do
      post pets_url, params: { pet: { name: "Milo", species: "Cat", time_zone: "Brasilia" } }
    end

    pet = Pet.order(:created_at).last
    assert_redirected_to pet_meal_slots_url(pet)
    assert pet.pet_users.exists?(user: users(:one), is_pet_admin: true)
  end

  test "does not expose another user's pet" do
    get pet_url(pets(:two))
    assert_response :not_found
  end

  test "requires exact name confirmation to delete" do
    assert_no_difference "Pet.count" do
      delete pet_url(pets(:one)), params: { confirmation: "wrong" }
    end
    assert_redirected_to edit_pet_url(pets(:one))
  end

  test "administrator can delete with exact confirmation" do
    assert_difference "Pet.count", -1 do
      delete pet_url(pets(:one)), params: { confirmation: "Pepper" }
    end
    assert_redirected_to pets_url
  end
end
