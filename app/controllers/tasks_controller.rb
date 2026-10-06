class TasksController < ApplicationController
  include TaskParameters
  before_action :set_household
  def index
    @tasks = @household.tasks.active.order(:title)
  end
  def new
    @task = @household.tasks.new(time_zone: @household.time_zone, starts_on: Time.current.in_time_zone(@household.time_zone).to_date, local_time: "09:00")
  end
  def create
    @task = @household.tasks.new(time_zone: @household.time_zone)
    Tasks::Save.call(task: @task, attributes: task_attributes(@household))
    redirect_to household_tasks_path(@household)
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end
  def edit
    @task = @household.tasks.find_by!(public_id: params[:id])
  end
  def update
    @task = @household.tasks.find_by!(public_id: params[:id])
    Tasks::Save.call(task: @task, attributes: task_attributes(@household))
    redirect_to household_tasks_path(@household)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end
  def destroy
    Tasks::Save.archive(@household.tasks.find_by!(public_id: params[:id]))
    redirect_to household_tasks_path(@household)
  end
  private
    def set_household
      @household = Current.user.households.find_by!(public_id: params[:household_id])
    end
end
