module Tasks
  class UpdateReminder
    def self.call(task:, user:, attributes:)
      raise ActiveRecord::RecordNotFound unless task.household.users.exists?(id: user.id)
      preference = TaskReminderPreference.for_user(task: task, user: user)
      preference.update!(attributes)
      preference
    end
  end
end
