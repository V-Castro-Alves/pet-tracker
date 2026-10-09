require "test_helper"

class PetsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the former global pet directory redirects to households" do
    get pets_url
    assert_redirected_to households_url
  end

  test "creates a pet inside an enabled household" do
    assert_difference "Pet.count", 1 do
      post pets_url, params: { household_id: households(:one).public_id, pet: { name: "Milo", species: "Cat" } }
    end

    pet = Pet.order(:created_at).last
    assert_redirected_to household_url(households(:one))
    assert_equal households(:one), pet.household
    assert_equal households(:one).time_zone, pet.time_zone
    assert_match(/\A[0-9a-f-]{36}\z/, pet.public_id)
  end

  test "uses an opaque public identifier in pet URLs" do
    assert_equal pets(:one).public_id, pets(:one).to_param

    get pet_url(pets(:one))
    assert_response :success
    assert_includes request.path, pets(:one).public_id
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
    assert_redirected_to household_url(households(:one))
  end
end
