class PetUsersController < ApplicationController
  before_action :set_pet

  def index
    @memberships = @pet.pet_users.includes(:user).order(is_pet_admin: :desc, linked_at: :asc)
    @pending_invites = @pet.pet_invites.pending.recent_first
    @invite = @pet.pet_invites.new
  end

  def destroy
    membership = @pet.pet_users.find(params[:id])
    PetUsers::Remove.new(pet: @pet, membership: membership, actor: Current.user).call

    destination = membership.user == Current.user ? root_path : pet_pet_users_path(@pet)
    redirect_to destination, status: :see_other, notice: "Caretaker access was removed."
  rescue PetUsers::Remove::LastMemberError, PetUsers::Remove::UnauthorizedError => error
    redirect_to pet_pet_users_path(@pet), alert: error.message
  end

  private
    def set_pet
      @pet = current_user_pet!
    end
end
