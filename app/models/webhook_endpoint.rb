require "uri"
class WebhookEndpoint < ApplicationRecord
  belongs_to :household
  belongs_to :user
  has_many :webhook_deliveries, dependent: :destroy
  before_validation -> { self.secret ||= SecureRandom.hex(32) }, on: :create
  validates :secret, presence: true
  validate do
    uri = URI.parse(url.to_s)
    errors.add(:url, "must be HTTPS without credentials or a fragment") unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.fragment.nil? && uri.port == 443
  rescue URI::InvalidURIError
    errors.add(:url, "is invalid")
  end
end
