class MealLogsController < ApplicationController
  before_action :set_pet

  def index
    @meal_logs = @pet.meal_logs.includes(:meal_slot, :logged_by_user).chronological
    @meal_logs = @meal_logs.where(logged_by_user_id: params[:logged_by_user_id]) if params[:logged_by_user_id].present?
    @meal_logs = @meal_logs.where(scheduled_for: Date.parse(params[:from]).beginning_of_day..) if params[:from].present?
  rescue Date::Error
    redirect_to pet_meal_logs_path(@pet), alert: "Choose a valid start date."
  end

  def new
    finder = Meals::OccurrenceFinder.new(@pet)
    @occurrence = if params[:meal_slot_id]
      finder.for(slot: @pet.meal_slots.active.find(params[:meal_slot_id]), date: requested_date)
    else
      finder.oldest_unresolved || finder.closest
    end
    redirect_to pet_meal_slots_path(@pet), alert: "Add a meal schedule before logging." unless @occurrence
  end

  def create
    @meal_slot = @pet.meal_slots.find(meal_log_params[:meal_slot_id])
    attributes = normalized_attributes
    @meal_log = Meals::LogMeal.new(
      pet: @pet,
      meal_slot: @meal_slot,
      user: Current.user,
      attributes: attributes,
      allow_duplicate: params[:allow_duplicate] == "1"
    ).call
    redirect_to pet_meal_logs_path(@pet), notice: "#{@meal_slot.name} was logged."
  rescue Meals::LogMeal::DuplicateMealError => error
    @duplicate = error.existing_log
    @occurrence = Meals::OccurrenceFinder::Occurrence.new(meal_slot: @meal_slot, scheduled_for: attributes[:scheduled_for])
    @form_values = meal_log_params
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    @meal_log = error.record
    @occurrence = Meals::OccurrenceFinder::Occurrence.new(meal_slot: @meal_slot, scheduled_for: attributes[:scheduled_for])
    @form_values = meal_log_params
    render :new, status: :unprocessable_entity
  end

  private
    def set_pet
      @pet = Current.user.pets.find(params[:pet_id])
    end

    def meal_log_params
      params.expect(meal_log: %i[meal_slot_id scheduled_for status actual_amount_g actual_time])
    end

    def normalized_attributes
      status = meal_log_params[:status]
      {
        scheduled_for: Time.iso8601(meal_log_params[:scheduled_for]),
        status: status,
        actual_amount_g: status == "fed" ? meal_log_params[:actual_amount_g] : nil,
        actual_time: status == "fed" ? parse_in_pet_zone(meal_log_params[:actual_time]) : nil
      }
    end

    def parse_in_pet_zone(value)
      Time.use_zone(@pet.time_zone) { Time.zone.parse(value) }
    end

    def requested_date
      params[:date].present? ? Date.iso8601(params[:date]) : Time.current.in_time_zone(@pet.time_zone).to_date
    end
end
