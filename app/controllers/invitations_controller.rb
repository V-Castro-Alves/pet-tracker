class InvitationsController < ApplicationController
  before_action :set_invite

  def show
  end

  def create
    pet = PetInvites::Accept.new(invite: @invite, user: Current.user).call
    redirect_to pet, notice: "You now help care for #{pet.name}."
  rescue PetInvites::Accept::UnavailableError, PetInvites::Accept::EmailMismatchError => error
    redirect_to invitation_path(@invite.invite_token), alert: error.message
  end

  private
    def set_invite
      @invite = PetInvite.find_by!(invite_token: params[:token])
    end
end
