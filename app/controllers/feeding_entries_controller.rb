class FeedingEntriesController < ApplicationController
  before_action :set_pet

  def index
    @occurrences = TaskOccurrence.where(
      task: @pet.tasks.joins(:pet_care_task_detail).where(pet_care_task_details: { care_type: "feeding" }),
      status: "pending"
    ).order(:scheduled_at).limit(30)
    @feedings = @pet.feeding_entries.includes(:credited_user).order(fed_at: :desc).limit(50)
  end

  def create
    Meals::RecordFeeding.call(pet: @pet, actor: Current.user, amount: params.expect(feeding_entry: [ :amount_g ])[:amount_g])
    redirect_to pet_feeding_entries_path(@pet), notice: "Additional feeding recorded."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to pet_feeding_entries_path(@pet), alert: error.record.errors.full_messages.to_sentence
  end

  private
    def set_pet
      @pet = current_user_pet!
    end
end
