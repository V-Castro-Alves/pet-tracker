require "test_helper"

class VaccinesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "creates a vaccine with no repeat date" do
    assert_difference "Vaccine.count", 1 do
      post pet_vaccines_url(pets(:one)), params: { vaccine: { name: "Bordetella", date_given: "2026-06-01", next_due_date: "", clinic: "Vet" } }
    end
    assert_redirected_to pet_vaccines_url(pets(:one))
  end

  test "updates and deletes an owned vaccine" do
    patch pet_vaccine_url(pets(:one), vaccines(:one_time)), params: { vaccine: { name: "Screening updated", date_given: "2026-07-01" } }
    assert_equal "Screening updated", vaccines(:one_time).reload.name

    assert_difference "Vaccine.count", -1 do
      delete pet_vaccine_url(pets(:one), vaccines(:one_time))
    end
  end

  test "cannot access another pet's vaccines" do
    get pet_vaccines_url(pets(:two))
    assert_response :not_found
  end
end
