class DeliverNotificationJob < ApplicationJob
  queue_as :background

  discard_on ActiveJob::DeserializationError

  def perform(notification)
    return unless vapid_configured?

    delivered = false
    notification.user.push_subscriptions.find_each do |subscription|
      deliver(subscription, notification)
      delivered = true
    rescue WebPush::ExpiredSubscription
      subscription.destroy!
    end
    notification.update!(delivered_at: Time.current) if delivered
  end

  private
    def deliver(subscription, notification)
      WebPush.payload_send(
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        message: JSON.generate(
          title: notification.title,
          options: {
            body: notification.body,
            icon: "/icon.png",
            badge: "/icon.png",
            data: { path: notification.path }
          }
        ),
        vapid: {
          subject: ENV.fetch("VAPID_SUBJECT", "mailto:notifications@pet-tracker.local"),
          public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
          private_key: ENV.fetch("VAPID_PRIVATE_KEY")
        },
        ttl: 3600
      )
    end

    def vapid_configured?
      ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
    end
end
