require "test_helper"

class MealNotificationJobTest < ActiveJob::TestCase
  test "publishes each unresolved occurrence idempotently" do
    pet = Pet.create!(name: "Scout", species: "Dog", time_zone: "UTC")
    pet.pet_users.create!(user: users(:one), linked_at: Time.current, is_pet_admin: true)
    slot = pet.meal_slots.create!(name: "Lunch", scheduled_time: "12:00", default_amount_g: 100, created_at: Time.utc(2026, 9, 1))
    now = Time.utc(2026, 9, 1, 13)
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
    slot = pet.meal_slots.create!(name: "Lunch", scheduled_time: "12:00", default_amount_g: 100, created_at: Time.utc(2026, 9, 1))
    slot.meal_reminder_preferences.create!(user: users(:one), delay_minutes: 5)
    now = Time.utc(2026, 9, 1, 12, 5)
    key = "meal:#{slot.id}:#{Time.utc(2026, 9, 1, 12).to_i}"

    assert_difference -> { pet.notifications.where(deduplication_key: key).count }, 1 do
      MealNotificationJob.perform_now(now: now)
    end
    assert_no_difference -> { pet.notifications.where(deduplication_key: key).count } do
      MealNotificationJob.perform_now(now: now)
    end
  end
  test "personal delays, opt out, midnight, and delayed worker catch up" do
    pet = pets(:one)
    pet.update!(time_zone: "Brasilia")
    slot = meal_slots(:breakfast)
    slot.update_column(:created_at, Time.utc(2026, 9, 1))
    slot.update!(scheduled_time: "23:50")
    second = users(:two)
    pet.pet_users.create!(user: second, linked_at: Time.current)
    slot.meal_reminder_preferences.create!(user: users(:one), delay_minutes: 5)
    preference = slot.meal_reminder_preferences.create!(user: second, delay_minutes: 30)
    scheduled = Time.utc(2026, 9, 2, 2, 50)
    key = "meal:#{slot.id}:#{scheduled.to_i}"

    MealNotificationJob.perform_now(now: scheduled + 4.minutes)
    assert_empty pet.notifications.where(deduplication_key: key)
    MealNotificationJob.perform_now(now: scheduled + 5.minutes)
    assert_equal [ users(:one).id ], pet.notifications.where(deduplication_key: key).pluck(:user_id)
    MealNotificationJob.perform_now(now: scheduled + 45.minutes)
    assert_equal [ users(:one).id, second.id ].sort, pet.notifications.where(deduplication_key: key).pluck(:user_id).sort
    preference.update!(enabled: false)
    next_key = "meal:#{slot.id}:#{(scheduled + 1.day).to_i}"
    MealNotificationJob.perform_now(now: scheduled + 1.day + 60.minutes)
    assert_equal [ users(:one).id ], pet.notifications.where(deduplication_key: next_key).pluck(:user_id)
  end

  test "resolved meals and inactive slots do not notify" do
    slot = meal_slots(:breakfast)
    scheduled = meal_logs(:breakfast_today).scheduled_for
    slot.update_column(:created_at, scheduled - 1.day)
    MealNotificationJob.perform_now(now: scheduled + 60.minutes)
    assert_empty slot.pet.notifications.where(deduplication_key: "meal:#{slot.id}:#{scheduled.to_i}")
    slot.update!(active: false)
    assert_no_difference -> { slot.pet.notifications.where("deduplication_key LIKE ?", "meal:#{slot.id}:%").count } do
      MealNotificationJob.perform_now(now: scheduled + 1.day + 60.minutes)
    end
  end

  test "does not notify for dates before the meal was created" do
    pet = Pet.create!(name: "Scout", species: "Dog", time_zone: "Brasilia")
    pet.pet_users.create!(user: users(:one), linked_at: Time.current, is_pet_admin: true)
    slot = pet.meal_slots.create!(name: "Late meal", scheduled_time: "23:50", default_amount_g: 100, created_at: Time.utc(2026, 9, 6, 3))
    prior_occurrence = Time.utc(2026, 9, 6, 2, 50)
    key = "meal:#{slot.id}:#{prior_occurrence.to_i}"

    MealNotificationJob.perform_now(now: Time.utc(2026, 9, 6, 3, 30))

    assert_empty pet.notifications.where(deduplication_key: key)
  end
end
