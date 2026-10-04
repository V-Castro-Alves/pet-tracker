class DashboardController < ApplicationController
  def show
    @pets = Current.user.pets.with_attached_photo.order(:name)
    @now = Time.current
    @due_reminders, @upcoming_reminders = Meals::DashboardReminders.new(Current.user, now: @now).call.partition { |reminder| reminder.due_at <= @now }
  end
end
