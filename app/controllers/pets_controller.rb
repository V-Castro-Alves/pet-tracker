class PetsController < ApplicationController
  before_action :set_pet, only: %i[show edit update destroy]
  before_action :require_pet_admin, only: :destroy

  def index
    @pets = Current.user.pets.with_attached_photo.order(:name)
  end

  def show
  end

  def new
    @household = Current.user.households.find_by!(public_id: params[:household_id]) if params[:household_id].present?
    @household ||= Current.user.households.where(pets_enabled: true).first
    if Current.user.households.exists? && !@household
      return redirect_to households_path, alert: "Enable pet care in a household first."
    end
    @pet = Pet.new(time_zone: @household&.time_zone || Current.user.time_zone)
  end

  def create
    @pet = Pet.new(pet_params.merge(time_zone: Current.user.time_zone))

    if params[:household_id].present? || Current.user.households.exists?
      @pet.household = Current.user.households.find_by!(public_id: params[:household_id])
      return head :forbidden unless @pet.household.pets_enabled?
      @pet.time_zone = @pet.household.time_zone
    end

    Pet.transaction do
      @pet.save!
      @pet.pet_users.create!(user: Current.user, is_pet_admin: true, linked_at: Time.current) unless @pet.household
    end

    redirect_to(@pet.household ? new_household_task_path(@pet.household) : pet_meal_slots_path(@pet), notice: "#{@pet.name} was added. Now set up a feeding schedule.")
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
    redirect_to pets_path, status: :see_other, notice: "#{@pet.name} was deleted."
  end

  private
    def set_pet
      @pet = current_user_pet!
    end

    def require_pet_admin
      return if @pet.administered_by?(Current.user)

      redirect_to @pet, alert: "Only a pet administrator can do that."
    end

    def pet_params
      params.expect(pet: %i[name species breed birthdate sex notes photo])
    end
end
