class DomainEvent < ApplicationRecord
  include PublicIdentifier
  belongs_to :household
  has_many :webhook_deliveries, dependent: :destroy
  def self.publish!(household:, kind:, resource:, key: SecureRandom.uuid)
    find_or_create_by!(deduplication_key: key) do |event|
      event.household = household
      event.kind = kind
      event.payload = { version: 1, resource_id: resource.public_id, household_id: household.public_id }
    end
  end
end
