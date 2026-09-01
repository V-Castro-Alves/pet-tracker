class QrCodesController < ApplicationController
  before_action :set_pet
  before_action :require_pet_admin, only: :regenerate

  def show
    @meal_log_url = qr_meal_log_url(qr_token: @pet.qr_token)
    @qr_svg = QrCodes::Generator.new(@meal_log_url).svg
  end

  def download
    meal_log_url = qr_meal_log_url(qr_token: @pet.qr_token)
    svg = QrCodes::Generator.new(meal_log_url).svg
    send_data svg,
      filename: "#{@pet.name.parameterize}-meal-qr.svg",
      type: "image/svg+xml",
      disposition: "attachment"
  end

  def regenerate
    @pet.regenerate_qr_token
    redirect_to pet_qr_code_path(@pet), notice: "A new QR code was generated. The old code no longer works."
  end

  private
    def set_pet
      @pet = Current.user.pets.find(params[:pet_id])
    end

    def require_pet_admin
      return if @pet.administered_by?(Current.user)

      redirect_to pet_qr_code_path(@pet), alert: "Only a pet administrator can regenerate the QR code."
    end
end
