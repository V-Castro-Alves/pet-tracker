class WebhookDelivery < ApplicationRecord
  belongs_to :domain_event
  belongs_to :webhook_endpoint
end
