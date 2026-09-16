class DeliverNotificationJob < ApplicationJob
  queue_as :background

  discard_on ActiveJob::DeserializationError

  def perform(notification)
    return unless vapid_configured?

    delivered = false
    first_error = nil
    notification.user.push_subscriptions.find_each do |subscription|
      deliver(subscription, notification)
      delivered = true
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      subscription.destroy!
    rescue WebPush::ResponseError => error
      first_error ||= error
      Rails.logger.warn("Push delivery failed for subscription #{subscription.id}: #{error.class}")
    end
    notification.update!(delivered_at: Time.current) if delivered
    raise first_error if first_error
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
          subject: ENV.fetch("VAPID_SUBJECT", "https://vitor.tail32ad45.ts.net"),
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
