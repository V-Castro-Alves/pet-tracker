class QrMealLogsController < ApplicationController
  def show
    pet = Pet.find_by!(qr_token: params[:qr_token])

    unless Current.user.pets.exists?(id: pet.id)
      render :forbidden, status: :forbidden
      return
    end

    redirect_to new_pet_meal_log_path(pet, source: "qr")
  end
end
