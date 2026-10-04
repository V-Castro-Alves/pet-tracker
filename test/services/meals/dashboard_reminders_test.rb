require "test_helper"

class Meals::DashboardRemindersTest < ActiveSupport::TestCase
  setup do
    @now = Time.utc(2026, 9, 26, 12)
    MealLog.delete_all
    MealSlot.update_all(created_at: @now.beginning_of_day)
  end

  test "aggregates linked pets and sorts by actual reminder time" do
    PetUser.create!(pet: pets(:two), user: users(:one), linked_at: @now, is_pet_admin: false)
    meal_slots(:other_pet_breakfast).update!(scheduled_time: "07:00")
    reminders = Meals::DashboardReminders.new(users(:one), now: @now).call
    assert_equal [ "Luna", "Pepper", "Pepper" ], reminders.map { |reminder| reminder.pet.name }
    assert_equal [ 8, 9, 19 ], reminders.map { |reminder| reminder.due_at.hour }
  end

  test "excludes unlinked pets inactive slots and occurrences before creation" do
    meal_slots(:breakfast).update!(active: false)
    meal_slots(:dinner).update_column(:created_at, @now + 1.day)
    assert_empty Meals::DashboardReminders.new(users(:one), now: @now).call
  end

  test "hides fed and skipped occurrences" do
    %i[breakfast dinner].zip(%w[fed skipped]).each do |slot_name, status|
      slot = meal_slots(slot_name)
      scheduled_for = Meals::OccurrenceFinder.new(pets(:one), now: @now).for(slot: slot).scheduled_for
      MealLog.create!(pet: pets(:one), meal_slot: slot, logged_by_user: users(:one), scheduled_for: scheduled_for,
        status: status, actual_amount_g: status == "fed" ? 100 : nil, actual_time: status == "fed" ? @now : nil)
    end
    assert_empty Meals::DashboardReminders.new(users(:one), now: @now).call
  end

  test "uses only the viewing user's weekday and opt-out preferences" do
    meal_slots(:breakfast).meal_reminder_preferences.create!(user: users(:one), enabled: true, delay_minutes: 60, weekday_delays: { "6" => nil })
    meal_slots(:dinner).meal_reminder_preferences.create!(user: users(:two), enabled: false)
    reminders = Meals::DashboardReminders.new(users(:one), now: @now).call
    assert_equal [ meal_slots(:dinner) ], reminders.map(&:meal_slot)
    assert_equal 19, reminders.first.due_at.hour
    meal_slots(:dinner).meal_reminder_preferences.create!(user: users(:one), enabled: false)
    assert_empty Meals::DashboardReminders.new(users(:one), now: @now).call
  end

  test "uses occurrence weekday across midnight and the user's day boundary" do
    users(:one).update!(time_zone: "UTC")
    pets(:one).update!(time_zone: "Brasilia")
    slot = meal_slots(:dinner)
    slot.update!(scheduled_time: "23:30", created_at: Time.utc(2026, 9, 25))
    slot.meal_reminder_preferences.create!(user: users(:one), weekday_delays: { "5" => 120, "6" => nil })
    meal_slots(:breakfast).update!(active: false)
    reminders = Meals::DashboardReminders.new(users(:one), now: Time.utc(2026, 9, 26, 4)).call
    assert_equal 1, reminders.size
    assert_equal Time.utc(2026, 9, 26, 4, 30), reminders.first.due_at
    assert_equal Date.new(2026, 9, 25), reminders.first.scheduled_for.in_time_zone("Brasilia").to_date
  end

  test "excludes stale reminders and reminders after the viewer's today" do
    MealSlot.update_all(created_at: @now - 7.days)
    users(:one).update!(time_zone: "Tokyo")
    reminders = Meals::DashboardReminders.new(users(:one), now: @now).call
    assert reminders.all? { |reminder| reminder.due_at >= @now - 1.day && reminder.due_at <= @now.in_time_zone("Tokyo").end_of_day }
    assert_equal [ Time.utc(2026, 9, 25, 19), Time.utc(2026, 9, 26, 9) ], reminders.map(&:due_at)
  end
end
