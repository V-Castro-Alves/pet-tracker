class PetsController < ApplicationController
  before_action :set_pet, only: %i[show edit update destroy]
  before_action :require_pet_admin, only: :destroy

  def index
    redirect_to households_path, notice: "Choose a household to manage Pet Care."
  end

  def show
  end

  def new
    @household = Current.user.households.find_by!(public_id: params[:household_id]) if params[:household_id].present?
    @household ||= Current.user.households.joins(:household_modules).find_by(household_modules: { key: "pet_care" })
    if Current.user.households.exists? && !@household
      return redirect_to households_path, alert: "Enable pet care in a household first."
    end
    @pet = Pet.new(time_zone: @household&.time_zone || Current.user.time_zone)
  end

  def create
    @pet = Pet.new(pet_params.merge(time_zone: Current.user.time_zone))

    if params[:household_id].present? || Current.user.households.exists?
      @pet.household = Current.user.households.find_by!(public_id: params[:household_id])
      return head :forbidden unless @pet.household.pet_care_enabled?
      @pet.time_zone = @pet.household.time_zone
    end

    Pet.transaction do
      @pet.save!
    end

    redirect_to(@pet.household, notice: "#{@pet.name} was added to Pet Care.")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if @pet.update(pet_params)
      redirect_to @pet, notice: "#{@pet.name}'s profile was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless params[:confirmation] == @pet.name
      redirect_to edit_pet_path(@pet), alert: "Enter #{@pet.name} exactly to delete this shared pet."
      return
    end

    @pet.destroy!
    redirect_to household_path(@pet.household), status: :see_other, notice: "#{@pet.name} was deleted."
  end

  private
    def set_pet
      @pet = current_user_pet!
    end

    def require_pet_admin
      return if @pet.household.administered_by?(Current.user)

      redirect_to @pet, alert: "Only a pet administrator can do that."
    end

    def pet_params
      params.expect(pet: %i[name species breed birthdate sex notes photo])
    end
end
