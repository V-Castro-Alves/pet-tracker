class CreateSchedulerHeartbeats < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduler_heartbeats do |t|
      t.string :name, null: false, index: { unique: true }
      t.datetime :started_at
      t.datetime :completed_at
      t.string :last_error
      t.timestamps
    end
    add_check_constraint :task_occurrences, "status IN ('pending', 'completed', 'skipped')", name: "task_occurrences_valid_status"
    add_check_constraint :tasks, "recurrence IN ('once', 'daily', 'weekly')", name: "tasks_valid_recurrence"
    add_check_constraint :task_reminder_preferences, "delay_minutes >= 0 AND delay_minutes <= 1440", name: "task_reminder_delay_range"
  end
end
