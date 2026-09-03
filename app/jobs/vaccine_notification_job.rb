class VaccineNotificationJob < ApplicationJob
  queue_as :background

  def perform(on: Date.current)
    Vaccine.includes(:pet).find_each do |vaccine|
      status = vaccine.due_status(on: on)
      next unless status.in?(%i[due_soon overdue])

      Notifications::Publish.new(
        pet: vaccine.pet,
        kind: "vaccine_due",
        title: "#{vaccine.name} #{status.to_s.humanize.downcase}",
        body: "#{vaccine.pet.name}'s #{vaccine.name} is due #{I18n.l(vaccine.next_due_date, format: :long)}.",
        path: Rails.application.routes.url_helpers.pet_vaccines_path(vaccine.pet),
        deduplication_key: "vaccine:#{vaccine.id}:#{status}:#{vaccine.next_due_date.iso8601}"
      ).call
    end
  end
end
