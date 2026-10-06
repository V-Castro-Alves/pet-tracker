require "test_helper"
class HouseholdsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @household = Household.create!(name: "Home", time_zone: "UTC", pets_enabled: true)
    @household.memberships.create!(user: users(:one), admin: true)
  end
  test "registration returns to a household invitation" do
    invitation = @household.household_invitations.create!(email: "new@example.com")
    get household_invitation_path(invitation.token)
    assert_redirected_to new_session_path
    post registration_path, params: { user: { name: "New", email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }
    assert_redirected_to household_invitation_url(invitation.token)
    post household_invitation_path(invitation.token)
    assert_redirected_to household_path(@household)
    assert @household.users.exists?(email_address: "new@example.com")
  end
  test "non-admin members cannot change settings or configure webhooks" do
    @household.memberships.create!(user: users(:two))
    sign_in_as users(:two)
    patch household_path(@household), params: { household: { name: "Changed" } }
    assert_response :forbidden
    post household_integrations_path(@household), params: { kind: "webhook", url: "https://example.com" }
    assert_response :forbidden
  end
  test "household pets do not grant access through old pet membership" do
    pet = pets(:one)
    pet.update!(household: @household)
    @household.memberships.delete_all
    sign_in_as users(:one)
    get pet_path(pet)
    assert_response :not_found
    get qr_meal_log_path(pet.qr_token)
    assert_response :forbidden
  end
  test "reminder form saves weekday settings for the signed in member" do
    sign_in_as users(:one)
    task = Tasks::Save.call(task: @household.tasks.new, attributes: { title: "Trash", recurrence: "once", starts_on: Date.current, local_time: "09:00", time_zone: "UTC" })
    get edit_household_task_reminder_path(@household, task)
    assert_response :success
    patch household_task_reminder_path(@household, task), params: { reminder: { enabled: "1", delay_minutes: "30", weekdays: { "0" => { mode: "off" }, "1" => { mode: "custom", minutes: "120" } } } }
    assert_redirected_to household_tasks_path(@household)
    assert_equal({ "0" => nil, "1" => 120 }, task.task_reminder_preferences.find_by!(user: users(:one)).weekday_delays)
  end
end
