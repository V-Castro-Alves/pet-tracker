module Tasks
  class Save
    def self.call(task:, attributes:)
      Task.transaction do
        creating = task.new_record?
        task.assign_attributes(attributes)
        task.time_zone = task.pet.time_zone if task.pet
        schedule_changed = (task.changed & %w[recurrence starts_on local_time weekdays time_zone]).any?
        assignment_changed = task.assignee_id_changed?
        task.save!
        if schedule_changed && !creating
          task.task_occurrences.where(status: "pending").where("scheduled_at > ?", Time.current).destroy_all
        end
        task.task_occurrences.where(status: "pending").update_all(assignee_id: task.assignee_id) if assignment_changed
        GenerateOccurrences.call(task)
        DomainEvent.publish!(household: task.household, kind: creating ? "task.created" : "task.updated", resource: task)
        task
      end
    end
    def self.archive(task)
      task.with_lock do
        task.update!(archived_at: Time.current)
        task.task_occurrences.where(status: "pending").where("scheduled_at > ?", Time.current).destroy_all
        DomainEvent.publish!(household: task.household, kind: "task.archived", resource: task)
      end
    end
  end
end
