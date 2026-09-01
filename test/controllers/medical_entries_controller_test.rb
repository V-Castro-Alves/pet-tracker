require "test_helper"

class MedicalEntriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "creates an authored medical entry" do
    assert_difference "MedicalEntry.count", 1 do
      post pet_medical_entries_url(pets(:one)), params: { medical_entry: { entry_date: "2026-08-20", title: "Ear check", body: "No infection found." } }
    end
    assert_equal users(:one), MedicalEntry.find_by!(title: "Ear check").created_by
  end

  test "updates and deletes an owned entry without changing its author" do
    entry = medical_entries(:checkup)
    patch pet_medical_entry_url(pets(:one), entry), params: { medical_entry: { entry_date: entry.entry_date, title: "Updated", body: "Updated details" } }
    assert_equal users(:one), entry.reload.created_by
    assert_equal "Updated", entry.title

    assert_difference "MedicalEntry.count", -1 do
      delete pet_medical_entry_url(pets(:one), entry)
    end
  end

  test "cannot access another pet's medical history" do
    get pet_medical_entries_url(pets(:two))
    assert_response :not_found
  end
end
