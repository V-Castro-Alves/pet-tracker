class WebhookDeliveryJob < ApplicationJob
  queue_as :background
  def perform(delivery)
    Webhooks::Deliver.call(delivery)
  end
end
