class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new(time_zone: cookies[:time_zone] || "UTC")
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Welcome to Pet Tracker!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: %i[name email_address time_zone password password_confirmation])
    end
end
