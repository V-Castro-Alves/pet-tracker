module Tasks
  class GenerateOccurrences
    def self.call(task, now: Time.current)
      task.with_lock do
        return if task.archived_at
        today = now.in_time_zone(task.time_zone).to_date
        last_date = task.task_occurrences.maximum(:local_date)
        first = [ task.starts_on, last_date || task.starts_on ].max
        (first..(today + 14)).each do |date|
          next unless task.occurs_on?(date)
          hour, minute = task.local_time.split(":").map(&:to_i)
          time = ActiveSupport::TimeZone[task.time_zone].local(date.year, date.month, date.day, hour, minute)
          task.task_occurrences.find_or_create_by!(local_date: date) do |occurrence|
            occurrence.scheduled_at = time
            occurrence.assignee = task.assignee
          end
        end
      end
    end
  end
end
