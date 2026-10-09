class HouseholdModulesController < ApplicationController
  before_action :set_household
  before_action :require_administrator

  def create
    key = params.expect(:key)
    @household.household_modules.find_or_create_by!(key: key) do |household_module|
      household_module.enabled_by = Current.user
      household_module.enabled_at = Time.current
    end
    redirect_to @household, notice: "#{module_name(key)} is now available in #{@household.name}."
  end

  def destroy
    key = params.expect(:key)
    @household.household_modules.find_by!(key: key).destroy!
    redirect_to @household, notice: "#{module_name(key)} was disabled. Existing information was kept."
  end

  private
    def set_household
      @household = Current.user.households.find_by!(public_id: params[:household_id])
    end

    def require_administrator
      head :forbidden unless @household.administered_by?(Current.user)
    end

    def module_name(key)
      HouseholdModule::KEYS.include?(key) ? key.humanize.titleize : raise(ActiveRecord::RecordNotFound)
    end
end
