class MedicalEntriesController < ApplicationController
  before_action :set_pet
  before_action :set_medical_entry, only: %i[edit update destroy]

  def index
    @medical_entries = @pet.medical_entries.includes(:created_by).chronological
  end

  def new
    @medical_entry = @pet.medical_entries.new(entry_date: Date.current)
  end

  def create
    @medical_entry = @pet.medical_entries.new(medical_entry_params.merge(created_by: Current.user))
    if @medical_entry.save
      redirect_to pet_medical_entries_path(@pet), notice: "Medical entry added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @medical_entry.update(medical_entry_params)
      redirect_to pet_medical_entries_path(@pet), notice: "Medical entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_entry.destroy!
    redirect_to pet_medical_entries_path(@pet), status: :see_other, notice: "Medical entry deleted."
  end

  private
    def set_pet
      @pet = current_user_pet!
    end

    def set_medical_entry
      @medical_entry = @pet.medical_entries.find(params[:id])
    end

    def medical_entry_params
      params.expect(medical_entry: %i[entry_date title body])
    end
end
