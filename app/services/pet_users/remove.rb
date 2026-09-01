module PetUsers
  class Remove
    class LastMemberError < StandardError; end
    class UnauthorizedError < StandardError; end

    def initialize(pet:, membership:, actor:)
      @pet = pet
      @membership = membership
      @actor = actor
    end

    def call
      pet.with_lock do
        authorize!
        raise LastMemberError, "A pet must always have at least one caretaker." if pet.pet_users.count == 1

        was_admin = membership.is_pet_admin?
        membership.destroy!
        promote_successor! if was_admin && !pet.pet_users.exists?(is_pet_admin: true)
      end
    end

    private
      attr_reader :pet, :membership, :actor

      def authorize!
        return if membership.user == actor
        return if pet.administered_by?(actor)

        raise UnauthorizedError, "Only a pet administrator can remove another caretaker."
      end

      def promote_successor!
        pet.pet_users.order(:linked_at, :id).first.update!(is_pet_admin: true)
      end
  end
end
