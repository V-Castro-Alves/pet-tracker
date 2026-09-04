class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new(time_zone: cookies[:time_zone] || "UTC")
  end

  def create
    @user = User.new(registration_params.merge(time_zone: resolved_time_zone))

    if @user.save
      start_new_session_for(@user)
      redirect_to after_registration_url, notice: "Welcome to Pet Tracker!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: %i[name email_address browser_time_zone password password_confirmation]).except(:browser_time_zone)
    end

    def resolved_time_zone
      browser_zone = params.dig(:user, :browser_time_zone)
      ActiveSupport::TimeZone.all.find { |zone| zone.tzinfo.identifier == browser_zone }&.name || "UTC"
    end

    def after_registration_url
      protected_destination = session.delete(:return_to_after_authenticating)
      return protected_destination if protected_destination && URI.parse(protected_destination).path.start_with?("/invites/")

      root_url
    rescue URI::InvalidURIError
      root_url
    end
end
