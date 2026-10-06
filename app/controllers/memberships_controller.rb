class MembershipsController < ApplicationController
  def destroy
    household = Current.user.households.find_by!(public_id: params[:household_id])
    membership = household.memberships.joins(:user).find_by!(users: { public_id: params[:id] })
    Households::RemoveMember.call(household: household, membership: membership, actor: Current.user)
    redirect_to households_path
  rescue ActiveRecord::RecordInvalid => error
    redirect_to households_path, alert: error.record.errors.full_messages.to_sentence
  end
end
