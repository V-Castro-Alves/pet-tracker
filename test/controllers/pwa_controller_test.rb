require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "service worker handles push and notification clicks" do
    get pwa_service_worker_url(format: :js)
    assert_response :success
    assert_includes response.body, 'addEventListener("push"'
    assert_includes response.body, 'addEventListener("notificationclick"'
  end

  test "manifest uses product colors and standalone display" do
    get pwa_manifest_url(format: :json)
    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal "standalone", manifest["display"]
    assert_equal "#247a55", manifest["theme_color"]
  end
end
