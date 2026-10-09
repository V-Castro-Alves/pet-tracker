require "test_helper"

class HouseholdModulesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "an administrator can disable and restore Pet Care without deleting pets" do
    assert_no_difference "Pet.count" do
      delete household_module_url(households(:one), "pet_care")
    end
    assert_redirected_to household_url(households(:one))
    assert_not households(:one).reload.pet_care_enabled?
    assert_not_includes users(:one).pets, pets(:one)

    post household_modules_url(households(:one)), params: { key: "pet_care" }
    assert_redirected_to household_url(households(:one))
    assert households(:one).reload.pet_care_enabled?
    assert_includes users(:one).pets, pets(:one)
  end

  test "a non-administrator cannot manage modules" do
    households(:one).memberships.create!(user: users(:two))
    sign_out
    sign_in_as users(:two)

    delete household_module_url(households(:one), "pet_care")
    assert_response :forbidden
    assert households(:one).reload.pet_care_enabled?
  end
end
