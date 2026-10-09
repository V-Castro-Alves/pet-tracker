class HouseholdsController < ApplicationController
  def index
    @households = Current.user.households.order(:name)
  end
  def new
    @household = Household.new(time_zone: Current.user.time_zone)
  end
  def create
    @household = Household.new(params.expect(household: %i[name time_zone]))
    Household.transaction do
      @household.save!
      @household.memberships.create!(user: Current.user, admin: true)
    end
    redirect_to @household
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end
  def show
    @household = Current.user.households.find_by!(public_id: params[:id])
  end
  def update
    @household = Current.user.households.find_by!(public_id: params[:id])
    return head :forbidden unless @household.administered_by?(Current.user)
    @household.update!(params.expect(household: %i[name time_zone]))
    redirect_to @household
  rescue ActiveRecord::RecordInvalid
    render :show, status: :unprocessable_entity
  end
end
