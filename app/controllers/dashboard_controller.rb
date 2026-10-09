class DashboardController < ApplicationController
  def show
    @households = Current.user.households.order(:name)
    selected = params[:household_id].present? ? @households.where(public_id: params[:household_id]) : @households
    tasks = Task.where(household: selected)
    scope = TaskOccurrence.where(task: tasks).includes(:assignee, :credited_user, task: :household).order(:scheduled_at)
    scope = scope.where(assignee: Current.user) if params[:view] == "mine"
    today = Time.current.in_time_zone(Current.user.time_zone).beginning_of_day
    pending = scope.where(status: "pending")
    @groups = { "Overdue" => pending.where("scheduled_at < ?", today), "Today" => pending.where(scheduled_at: today...today + 1.day), "Upcoming" => pending.where("scheduled_at >= ?", today + 1.day).limit(100) }
    @activity = scope.where.not(status: "pending").reorder(resolved_at: :desc).limit(20)
  end
end
