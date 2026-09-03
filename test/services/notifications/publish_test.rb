require "test_helper"

class Notifications::PublishTest < ActiveSupport::TestCase
  test "publishes once per linked user and deduplication key" do
    PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current)
    publisher = Notifications::Publish.new(pet: pets(:one), kind: "food_low", title: "Low food", body: "Buy food", path: "/", deduplication_key: "bag:test")

    assert_difference "Notification.count", 2 do
      publisher.call
    end
    assert_no_difference "Notification.count" do
      publisher.call
    end
  end
end
