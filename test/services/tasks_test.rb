require "test_helper"
class TasksTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @household = Household.create!(name: "Our home", time_zone: "UTC", pets_enabled: true)
    @household.memberships.create!(user: @user, admin: true)
  end
  def build_task(**attributes)
    Tasks::Save.call(task: @household.tasks.new, attributes: { title: "Dishes", time_zone: "UTC", recurrence: "daily", starts_on: Date.new(2026, 10, 3), local_time: "09:00" }.merge(attributes))
  end
  test "generation is unique, bounded by schedule start, and resolution is final" do
    travel_to Time.utc(2026, 10, 3, 10) do
      task = build_task
      assert_equal 15, task.task_occurrences.count
      assert_no_difference "TaskOccurrence.count" do
        Tasks::GenerateOccurrences.call(task)
      end
      occurrence = task.task_occurrences.order(:scheduled_at).first
      Tasks::Resolve.call(occurrence: occurrence, actor: @user, status: "completed")
      assert_equal @user, occurrence.reload.actor
      assert_raises(Tasks::Resolve::Conflict) { Tasks::Resolve.call(occurrence: occurrence, actor: @user, status: "skipped") }
      assert_equal 1, DomainEvent.where(kind: "occurrence.completed").count
    end
  end
  test "schedule changes retain past history and replace future occurrences" do
    travel_to Time.utc(2026, 10, 3, 10) do
      task = build_task
      past = task.task_occurrences.order(:scheduled_at).first
      Tasks::Save.call(task: task, attributes: { local_time: "11:00" })
      assert_equal Time.utc(2026, 10, 3, 9), past.reload.scheduled_at
      assert_equal 11, task.task_occurrences.find_by!(local_date: Date.new(2026, 10, 4)).scheduled_at.hour
      Tasks::Save.archive(task)
      assert_equal [ past.id ], task.task_occurrences.pluck(:id)
    end
  end
  test "weekly and one-off schedules" do
    travel_to Time.utc(2026, 10, 3, 10) do
      assert_equal 1, build_task(recurrence: "once").task_occurrences.count
      weekly = build_task(recurrence: "weekly", weekdays: [ 1, 3 ])
      assert weekly.task_occurrences.all? { |item| [ 1, 3 ].include?(item.local_date.wday) }
    end
  end
  test "DST gaps move forward and repeated times occur once" do
    travel_to Time.utc(2026, 3, 8, 12) do
      task = build_task(time_zone: "Eastern Time (US & Canada)", starts_on: Date.new(2026, 3, 8), local_time: "02:30", recurrence: "once")
      assert_equal Time.utc(2026, 3, 8, 7, 30), task.task_occurrences.first.scheduled_at
    end
    travel_to Time.utc(2026, 11, 1, 12) do
      task = build_task(time_zone: "Eastern Time (US & Canada)", starts_on: Date.new(2026, 11, 1), local_time: "01:30", recurrence: "once")
      assert_equal 1, task.task_occurrences.count
    end
  end
  test "membership removal promotes successor and unassigns work" do
    @household.memberships.create!(user: users(:two))
    task = build_task(assignee: @user)
    Households::RemoveMember.call(household: @household, membership: @household.memberships.find_by!(user: @user), actor: @user)
    assert @household.administered_by?(users(:two))
    assert_nil task.reload.assignee
    assert task.task_occurrences.all? { |item| item.assignee_id.nil? }
    assert_raises(ActiveRecord::RecordInvalid) { Households::RemoveMember.call(household: @household, membership: @household.memberships.first, actor: users(:two)) }
  end
  test "invitations are email restricted and single use" do
    invitation = @household.household_invitations.create!(email: " TWO@example.com ")
    assert_raises(ActiveRecord::RecordInvalid) { invitation.accept!(@user) }
    invitation.accept!(users(:two))
    assert @household.users.include?(users(:two))
    assert_raises(ActiveRecord::RecordInvalid) { invitation.accept!(users(:two)) }
  end
  test "reminders and due events are deduplicated and resolved tasks suppressed" do
    travel_to Time.utc(2026, 10, 3, 10) do
      task = build_task(recurrence: "once")
      2.times { HouseholdSchedulerJob.perform_now }
      assert_equal 1, @user.notifications.where(kind: "task_due").count
      assert_equal 1, DomainEvent.where(kind: "occurrence.due").count
      Tasks::Resolve.call(occurrence: task.task_occurrences.first, actor: @user, status: "skipped")
      assert_no_difference "Notification.count" do
        HouseholdSchedulerJob.perform_now
      end
    end
  end
end
