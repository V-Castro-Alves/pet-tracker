class HouseholdSchedulerJob < ApplicationJob
  queue_as :background
  def perform(now: Time.current)
    heartbeat = SchedulerHeartbeat.find_or_create_by!(name: "household_scheduler")
    heartbeat.update!(started_at: Time.current)
    Task.active.find_each { |task| Tasks::GenerateOccurrences.call(task, now: now) }
    TaskOccurrence.where(status: "pending").where("scheduled_at <= ?", now).includes(task: :household).find_each do |occurrence|
      occurrence.with_lock do
        next unless occurrence.status == "pending"
        task = occurrence.task
        DomainEvent.publish!(household: task.household, kind: "occurrence.due", resource: occurrence, key: "due:#{occurrence.public_id}")
        next if occurrence.scheduled_at < now - 2.days
        task.household.users.each do |user|
          preference = task.task_reminder_preferences.find_by(user: user)
          next if !preference && occurrence.assignee_id && occurrence.assignee_id != user.id
          delay = preference ? preference.delay_for(occurrence.local_date) : 60
          next if delay.nil? || occurrence.scheduled_at + delay.minutes > now
          user.notifications.find_or_create_by!(deduplication_key: "task:#{occurrence.public_id}") do |notification|
            notification.assign_attributes(kind: "task_due", title: task.title, body: "This responsibility is waiting to be completed in #{task.household.name}.", path: "/", pet: task.pet)
          end
        end
      end
    end
    DomainEvent.find_each do |event|
      event.household.webhook_endpoints.where(active: true).where("created_at <= ?", event.created_at).find_each do |endpoint|
        event.webhook_deliveries.find_or_create_by!(webhook_endpoint: endpoint)
      end
    end
    WebhookDelivery.where(delivered_at: nil).where("attempts < 8").where("next_attempt_at IS NULL OR next_attempt_at <= ?", now).find_each do |delivery|
      WebhookDeliveryJob.perform_later(delivery)
    end
    heartbeat.update!(completed_at: Time.current, last_error: nil)
  rescue StandardError => error
    heartbeat&.update!(last_error: error.class.name)
    raise
  end
end
