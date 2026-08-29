class MealSlotsController < ApplicationController
  before_action :set_pet
  before_action :set_meal_slot, only: %i[edit update destroy]

  def index
    @meal_slots = @pet.meal_slots.active.chronological
  end

  def new
    @meal_slot = @pet.meal_slots.new
  end

  def create
    @meal_slot = @pet.meal_slots.new(meal_slot_params)

    if @meal_slot.save
      redirect_to pet_meal_slots_path(@pet), notice: "#{@meal_slot.name} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meal_slot.update(meal_slot_params)
      redirect_to pet_meal_slots_path(@pet), notice: "#{@meal_slot.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @meal_slot.update!(active: false)
    redirect_to pet_meal_slots_path(@pet), status: :see_other, notice: "#{@meal_slot.name} was removed from the schedule."
  end

  private
    def set_pet
      @pet = Current.user.pets.find(params[:pet_id])
    end

    def set_meal_slot
      @meal_slot = @pet.meal_slots.active.find(params[:id])
    end

    def meal_slot_params
      params.expect(meal_slot: %i[name scheduled_time default_amount_g])
    end
end
