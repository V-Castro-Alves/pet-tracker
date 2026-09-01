module PetInvites
  class Accept
    class UnavailableError < StandardError; end
    class EmailMismatchError < StandardError; end

    def initialize(invite:, user:)
      @invite = invite
      @user = user
    end

    def call
      invite.with_lock do
        return invite.pet if invite.accepted_by == user
        raise UnavailableError, "This invitation has already been used." if invite.accepted?
        raise UnavailableError, "This invitation has expired." if invite.expired?
        raise EmailMismatchError, "Sign in with #{invite.invited_email} to accept this invitation." unless invite.available_to?(user)

        invite.pet.pet_users.find_or_create_by!(user: user) do |membership|
          membership.linked_at = Time.current
          membership.is_pet_admin = false
        end
        invite.update!(accepted_at: Time.current, accepted_by: user)
        invite.pet
      end
    end

    private
      attr_reader :invite, :user
  end
end
