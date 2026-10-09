require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get root_url
    assert_redirected_to new_session_url
  end

  test "shows household responsibilities without a global pets destination" do
    Tasks::Save.call(task: households(:one).tasks.new, attributes: { title: "Take out recycling", recurrence: "once", starts_on: Date.current, local_time: "09:00", time_zone: "UTC" })
    sign_in_as users(:one)
    get root_url
    assert_response :success
    assert_select "h1", "Today"
    assert_select "h3", "Take out recycling"
    assert_select "nav a[href=?]", pets_path, count: 0
    assert_select "nav a[href=?]", households_path
  end

  test "new users get a single onboarding action" do
    user = User.create!(name: "New", email_address: "new-dashboard@example.com", password: "password", time_zone: "UTC")
    sign_in_as user
    get root_url
    assert_select "h2", "Create your first household"
    assert_select "a[href=?]", new_household_path, count: 1
    assert_select "a[href=?]", pets_path, count: 0
  end
end
