require "test_helper"

class PetUsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "lists linked caretakers" do
    get pet_pet_users_url(pets(:one))
    assert_response :success
    assert_select "h1", "Caretakers"
    assert_includes response.body, users(:one).email_address
  end

  test "cannot remove the final caretaker" do
    assert_no_difference "PetUser.count" do
      delete pet_pet_user_url(pets(:one), pet_users(:owner))
    end
    assert_redirected_to pet_pet_users_url(pets(:one))
  end

  test "cannot access another pet's caretaker list" do
    get pet_pet_users_url(pets(:two))
    assert_response :not_found
  end
end
