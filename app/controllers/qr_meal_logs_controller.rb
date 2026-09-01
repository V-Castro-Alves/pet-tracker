class QrMealLogsController < ApplicationController
  def show
    pet = Pet.find_by!(qr_token: params[:qr_token])

    unless pet.users.exists?(Current.user.id)
      render :forbidden, status: :forbidden
      return
    end

    redirect_to new_pet_meal_log_path(pet, source: "qr")
  end
end
