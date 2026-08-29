class DashboardController < ApplicationController
  def show
    @pets = Current.user.pets.with_attached_photo.order(:name)
  end
end
