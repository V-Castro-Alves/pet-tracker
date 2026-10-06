class HouseholdInvitationsController < ApplicationController
  def create
    household = Current.user.households.find_by!(public_id: params[:household_id])
    return head :forbidden unless household.administered_by?(Current.user)
    invitation = household.household_invitations.create!(email: params[:email])
    redirect_to household, notice: "Invitation link: #{household_invitation_url(invitation.token)}"
  end
  def show
    @invitation = HouseholdInvitation.find_by!(token: params[:token])
  end
  def accept
    invitation = HouseholdInvitation.find_by!(token: params[:token])
    invitation.accept!(Current.user)
    redirect_to invitation.household
  rescue ActiveRecord::RecordInvalid
    redirect_to households_path, alert: "This invitation is expired, already used, or belongs to another email address."
  end
end
