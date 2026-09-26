class MealRemindersController < ApplicationController
  before_action :set_reminder

  def edit
  end

  def update
    settings = params.expect(reminder_preference: [ weekdays: (0..6).to_h { |day| [ day.to_s, %i[timing minutes] ] } ])
    if @reminder_preference.update(settings)
      redirect_to pet_meal_slots_path(@pet), notice: "Your reminders were updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_reminder
      @pet = current_user_pet!
      @meal_slot = @pet.meal_slots.active.find(params[:meal_slot_id])
      @reminder_preference = @meal_slot.meal_reminder_preferences.find_or_initialize_by(user: Current.user)
    end
end
