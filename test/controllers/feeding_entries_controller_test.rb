require "test_helper"

class FeedingEntriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "records an additional household feeding" do
    assert_difference "pets(:one).feeding_entries.count", 1 do
      post pet_feeding_entries_url(pets(:one)), params: { feeding_entry: { amount_g: 75 } }
    end

    assert_redirected_to pet_feeding_entries_url(pets(:one))
    assert_equal users(:one), pets(:one).feeding_entries.order(:created_at).last.actor
  end

  test "does not expose another household's feedings" do
    get pet_feeding_entries_url(pets(:two))
    assert_response :not_found
  end
end
