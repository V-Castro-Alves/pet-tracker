module Notifications
  class Publish
    def initialize(pet:, kind:, title:, body:, path:, deduplication_key:)
      @pet = pet
      @attributes = { kind: kind, title: title, body: body, path: path, deduplication_key: deduplication_key }
    end

    def call
      pet.users.find_each.filter_map do |user|
        user.notifications.find_or_create_by!(deduplication_key: attributes[:deduplication_key]) do |notification|
          notification.assign_attributes(attributes.merge(pet: pet))
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        user.notifications.find_by!(deduplication_key: attributes[:deduplication_key])
      end
    end

    private
      attr_reader :pet, :attributes
  end
end
