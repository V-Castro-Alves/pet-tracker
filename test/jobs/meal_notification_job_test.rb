require "test_helper"

class MealNotificationJobTest < ActiveJob::TestCase
  test "publishes each unresolved occurrence idempotently" do
    pet = Pet.create!(name: "Scout", species: "Dog", time_zone: "UTC")
    pet.pet_users.create!(user: users(:one), linked_at: Time.current, is_pet_admin: true)
    slot = pet.meal_slots.create!(name: "Lunch", scheduled_time: "12:00", default_amount_g: 100)
    now = Time.utc(2026, 9, 1, 14)
    expected_key = "meal:#{slot.id}:#{Time.utc(2026, 9, 1, 12).to_i}"

    assert_difference -> { pet.notifications.where(deduplication_key: expected_key).count }, 1 do
      MealNotificationJob.perform_now(now: now)
    end
    assert_no_difference -> { pet.notifications.count } do
      MealNotificationJob.perform_now(now: now)
    end
  end

  test "publishes a scheduled reminder once" do
    pet = Pet.create!(name: "Scout", species: "Dog", time_zone: "UTC")
    pet.pet_users.create!(user: users(:one), linked_at: Time.current, is_pet_admin: true)
    slot = pet.meal_slots.create!(name: "Lunch", scheduled_time: "12:00", default_amount_g: 100)
    now = Time.utc(2026, 9, 1, 12, 5)
    key = "meal_reminder:#{slot.id}:#{Time.utc(2026, 9, 1, 12).to_i}"

    assert_difference -> { pet.notifications.where(deduplication_key: key).count }, 1 do
      MealNotificationJob.perform_now(now: now)
    end
    assert_no_difference -> { pet.notifications.where(deduplication_key: key).count } do
      MealNotificationJob.perform_now(now: now)
    end
  end
end
