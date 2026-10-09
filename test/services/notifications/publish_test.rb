require "test_helper"

class Notifications::PublishTest < ActiveSupport::TestCase
  test "publishes once per linked user and deduplication key" do
    households(:one).memberships.create!(user: users(:two))
    publisher = Notifications::Publish.new(pet: pets(:one), kind: "food_low", title: "Low food", body: "Buy food", path: "/", deduplication_key: "bag:test")

    assert_difference "Notification.count", 2 do
      publisher.call
    end
    assert_no_difference "Notification.count" do
      publisher.call
    end
  end
end
