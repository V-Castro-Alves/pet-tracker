class WeightLogsController < ApplicationController
  before_action :set_pet
  before_action :set_weight_log, only: %i[edit update destroy]

  def index
    @weight_logs = @pet.weight_logs.chronological
  end

  def new
    @weight_log = @pet.weight_logs.new(logged_at: Date.current)
  end

  def create
    @weight_log = @pet.weight_logs.new(weight_log_params)
    if @weight_log.save
      redirect_to pet_weight_logs_path(@pet), notice: "Weight entry added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @weight_log.update(weight_log_params)
      redirect_to pet_weight_logs_path(@pet), notice: "Weight entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weight_log.destroy!
    redirect_to pet_weight_logs_path(@pet), status: :see_other, notice: "Weight entry deleted."
  end

  private
    def set_pet
      @pet = Current.user.pets.find(params[:pet_id])
    end

    def set_weight_log
      @weight_log = @pet.weight_logs.find(params[:id])
    end

    def weight_log_params
      params.expect(weight_log: %i[weight_kg logged_at note])
    end
end
