class NotificationsController < ApplicationController
  def index
    @notifications = Current.user.notifications.includes(:pet).recent_first
  end

  def update
    notification = Current.user.notifications.find(params[:id])
    notification.update!(read_at: Time.current)
    redirect_to notification.path, status: :see_other
  end

  def read_all
    Current.user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)
    redirect_to notifications_path, status: :see_other, notice: "Notifications marked as read."
  end
end
