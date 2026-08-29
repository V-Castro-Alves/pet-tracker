require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get root_url
    assert_redirected_to new_session_url
  end

  test "shows the dashboard to signed-in users" do
    sign_in_as users(:one)
    get root_url
    assert_response :success
    assert_select "h1", "Your pets"
  end
end
