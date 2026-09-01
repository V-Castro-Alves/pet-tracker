class VaccinesController < ApplicationController
  before_action :set_pet
  before_action :set_vaccine, only: %i[edit update destroy]

  def index
    @vaccines = @pet.vaccines.by_due_date
  end

  def new
    @vaccine = @pet.vaccines.new(date_given: Date.current)
  end

  def create
    @vaccine = @pet.vaccines.new(vaccine_params)
    if @vaccine.save
      redirect_to pet_vaccines_path(@pet), notice: "Vaccine record added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @vaccine.update(vaccine_params)
      redirect_to pet_vaccines_path(@pet), notice: "Vaccine record updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @vaccine.destroy!
    redirect_to pet_vaccines_path(@pet), status: :see_other, notice: "Vaccine record deleted."
  end

  private
    def set_pet
      @pet = Current.user.pets.find(params[:pet_id])
    end

    def set_vaccine
      @vaccine = @pet.vaccines.find(params[:id])
    end

    def vaccine_params
      params.expect(vaccine: %i[name date_given next_due_date clinic notes])
    end
end
