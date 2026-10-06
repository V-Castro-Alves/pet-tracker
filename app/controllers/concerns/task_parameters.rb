module TaskParameters
  private
    def task_attributes(container)
      attrs = params.expect(task: [ :title, :notes, :category, :recurrence, :starts_on, :local_time, :time_zone, :feeding_amount_g, :assignee_id, :pet_id, weekdays: [] ]).to_h
      attrs["weekdays"] = attrs["weekdays"].reject(&:blank?).map { |value| Integer(value) } if attrs.key?("weekdays")
      if attrs.key?("assignee_id")
        attrs["assignee"] = attrs.delete("assignee_id").presence&.then { |id| container.users.find_by!(public_id: id) }
      end
      if attrs.key?("pet_id")
        attrs["pet"] = attrs.delete("pet_id").presence&.then { |id| container.pets.find_by!(public_id: id) }
      end
      attrs
    end
end
