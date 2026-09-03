require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "registers a device subscription" do
    assert_difference "PushSubscription.count", 1 do
      post push_subscriptions_url, params: { push_subscription: { endpoint: "https://push.example.test/new", keys: { p256dh: "key", auth: "secret" } } }, as: :json
    end
    assert_response :created
    assert_equal users(:one), PushSubscription.find_by!(endpoint: "https://push.example.test/new").user
  end

  test "removes only the current user's endpoint" do
    assert_difference "PushSubscription.count", -1 do
      delete push_subscription_url("current"), params: { endpoint: push_subscriptions(:one).endpoint }, as: :json
    end
    assert_response :no_content
  end
end
