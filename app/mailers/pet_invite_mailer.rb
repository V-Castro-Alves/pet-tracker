class PetInviteMailer < ApplicationMailer
  def invitation
    @invite = params[:invite]
    mail to: @invite.invited_email, subject: "You're invited to care for #{@invite.pet.name}"
  end
end
