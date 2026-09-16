require "test_helper"

class DeliverNotificationJobTest < ActiveJob::TestCase
  test "delivers configured push payload and marks the notification" do
    notification = notifications(:unread_food)
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "public-key"
    ENV["VAPID_PRIVATE_KEY"] = "private-key"
    payload = nil

    job = DeliverNotificationJob.new
    job.define_singleton_method(:deliver) do |subscription, delivered_notification|
      payload = { endpoint: subscription.endpoint, message: delivered_notification.title }
    end
    job.perform(notification)

    assert_equal push_subscriptions(:one).endpoint, payload[:endpoint]
    assert_includes payload[:message], notification.title
    assert notification.reload.delivered_at?
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "does nothing when VAPID is not configured" do
    notification = notifications(:unread_food)
    original_public = ENV.delete("VAPID_PUBLIC_KEY")
    original_private = ENV.delete("VAPID_PRIVATE_KEY")
    assert_no_changes -> { notification.reload.delivered_at } do
      DeliverNotificationJob.perform_now(notification)
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end
  test "one rejected device does not prevent another device receiving push" do
    notification = notifications(:unread_food)
    second = notification.user.push_subscriptions.create!(endpoint: "https://push.example.test/second", p256dh: "key", auth: "auth")
    response = Struct.new(:body).new('{"reason":"BadJwtToken"}')
    job = DeliverNotificationJob.new
    job.define_singleton_method(:vapid_configured?) { true }
    attempted = []
    job.define_singleton_method(:deliver) do |subscription, _|
      attempted << subscription.id
      raise WebPush::Unauthorized.new(response, "web.push.apple.com") unless subscription == second
    end

    assert_raises(WebPush::Unauthorized) { job.perform(notification) }
    assert_includes attempted, second.id
    assert notification.reload.delivered_at?
  end

  test "expired subscriptions are removed and delivery continues" do
    notification = notifications(:unread_food)
    response = Struct.new(:body).new("expired")
    job = DeliverNotificationJob.new
    job.define_singleton_method(:vapid_configured?) { true }
    job.define_singleton_method(:deliver) do |_, _notification|
      raise WebPush::ExpiredSubscription.new(response, "push.example.test")
    end
    assert_difference "PushSubscription.count", -1 do
      job.perform(notification)
    end
    assert_nil notification.reload.delivered_at
  end
end
