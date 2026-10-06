module Households
  class RemoveMember
    def self.call(household:, membership:, actor:)
      household.with_lock do
        raise ActiveRecord::RecordNotFound unless membership.household == household && (membership.user == actor || household.administered_by?(actor))
        if household.memberships.count == 1
          membership.errors.add(:base, "A household must retain one member")
          raise ActiveRecord::RecordInvalid, membership
        end
        household.tasks.where(assignee_id: membership.user_id).update_all(assignee_id: nil)
        TaskOccurrence.where(task: household.tasks, status: "pending", assignee_id: membership.user_id).update_all(assignee_id: nil)
        household.api_tokens.where(user_id: membership.user_id).update_all(revoked_at: Time.current)
        household.webhook_endpoints.where(user_id: membership.user_id).update_all(active: false)
        membership.destroy!
        household.memberships.order(:created_at, :id).first.update!(admin: true) unless household.memberships.exists?(admin: true)
      end
    end
  end
end
