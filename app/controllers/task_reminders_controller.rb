class TaskRemindersController < ApplicationController
  before_action :set_task
  def edit
    @preference = TaskReminderPreference.for_user(task: @task, user: Current.user)
  end
  def update
    attributes = params.expect(reminder: [ :enabled, :delay_minutes, weekdays: {} ]).to_h
    settings = attributes.delete("weekdays") || {}
    attributes["weekday_delays"] = settings.each_with_object({}) do |(day, setting), result|
      case setting["mode"]
      when "off" then result[day] = nil
      when "custom" then result[day] = Integer(setting["minutes"], 10)
      when "default" then next
      else raise ArgumentError, "Choose a weekday reminder option"
      end
    end
    Tasks::UpdateReminder.call(task: @task, user: Current.user, attributes: attributes)
    redirect_to household_tasks_path(@household), notice: "Your reminder preferences were saved."
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    edit
    flash.now[:alert] = error.is_a?(ActiveRecord::RecordInvalid) ? error.record.errors.full_messages.to_sentence : "Enter whole minutes between 0 and 1440."
    render :edit, status: :unprocessable_entity
  end
  private
    def set_task
      @household = Current.user.households.find_by!(public_id: params[:household_id])
      @task = @household.tasks.find_by!(public_id: params[:task_id])
    end
end
