class PetInvitesController < ApplicationController
  before_action :set_pet
  before_action :require_pet_admin

  def create
    @invite = @pet.pet_invites.new(invite_params.merge(
      created_by: Current.user,
      expires_at: PetInvite::EXPIRATION.from_now
    ))

    if @invite.save
      PetInviteMailer.with(invite: @invite).invitation.deliver_later if @invite.invited_email.present?
      redirect_to pet_pet_users_path(@pet), notice: "Invitation created."
    else
      @memberships = @pet.pet_users.includes(:user).order(is_pet_admin: :desc, linked_at: :asc)
      @pending_invites = @pet.pet_invites.pending.recent_first
      render "pet_users/index", status: :unprocessable_entity
    end
  end

  def destroy
    @pet.pet_invites.pending.find(params[:id]).destroy!
    redirect_to pet_pet_users_path(@pet), status: :see_other, notice: "Invitation revoked."
  end

  private
    def set_pet
      @pet = current_user_pet!
    end

    def require_pet_admin
      return if @pet.administered_by?(Current.user)

      redirect_to pet_pet_users_path(@pet), alert: "Only a pet administrator can manage invitations."
    end

    def invite_params
      params.expect(pet_invite: %i[invited_email])
    end
end
