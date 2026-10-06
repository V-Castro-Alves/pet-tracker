module Tasks
  class Resolve
    class Conflict < StandardError; end
    def self.call(occurrence:, actor:, status:, credited_user: actor, amount: nil)
      occurrence.with_lock do
        task = occurrence.task
        raise ActiveRecord::RecordNotFound unless task.household.users.exists?(id: actor.id) && task.household.users.exists?(id: credited_user.id)
        raise Conflict, "This occurrence has already been resolved" unless occurrence.status == "pending"
        raise ArgumentError, "Choose completed or skipped" unless status.in?(%w[completed skipped])
        claimed = TaskOccurrence.where(id: occurrence.id, status: "pending").update_all(status: status)
        raise Conflict, "This occurrence has already been resolved" unless claimed == 1
        amount = amount.presence || task.feeding_amount_g
        if status == "completed" && task.pet && task.feeding_amount_g
          raise ArgumentError, "Feeding amount must be positive" unless amount && BigDecimal(amount.to_s) > 0
          Meals::RecordFeeding.call(pet: task.pet, actor: actor, credited_user: credited_user, amount: amount, occurrence: occurrence)
        end
        occurrence.update!(status: status, actor: actor, credited_user: credited_user, resolved_at: Time.current,
          actual_amount_g: status == "completed" && task.pet ? amount : nil)
        DomainEvent.publish!(household: task.household, kind: "occurrence.#{status}", resource: occurrence, key: "resolved:#{occurrence.public_id}")
        occurrence
      end
    end
  end
end
