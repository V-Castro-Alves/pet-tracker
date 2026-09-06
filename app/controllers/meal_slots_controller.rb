class MealSlotsController < ApplicationController
  before_action :set_pet
  before_action :set_meal_slot, only: %i[edit update destroy]

  def index
    @meal_slots = @pet.meal_slots.active.chronological.includes(:meal_reminder_preferences)
  end

  def new
    @meal_slot = @pet.meal_slots.new
    set_reminder_preference
  end

  def create
    @meal_slot = @pet.meal_slots.new(meal_slot_params)

    set_reminder_preference
    if save_with_reminder
      redirect_to pet_meal_slots_path(@pet), notice: "#{@meal_slot.name} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @meal_slot.assign_attributes(meal_slot_params)
    if save_with_reminder
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
      @pet = current_user_pet!
    end

    def set_meal_slot
      @meal_slot = @pet.meal_slots.active.find(params[:id])
      set_reminder_preference
    end

    def set_reminder_preference
      @reminder_preference = @meal_slot.meal_reminder_preferences.find_or_initialize_by(user: Current.user)
    end

    def save_with_reminder
      if params[:reminder_preference]
        @reminder_preference.assign_attributes(params.expect(reminder_preference: %i[enabled delay_minutes]))
      end
      MealSlot.transaction do
        @meal_slot.save!
        @reminder_preference.save!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def meal_slot_params
      params.expect(meal_slot: %i[name scheduled_time default_amount_g])
    end
end
