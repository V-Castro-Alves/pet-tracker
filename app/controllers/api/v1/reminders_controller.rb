module Api
  module V1
    class RemindersController < BaseController
      def show
        render json: { data: preference.attributes.slice("enabled", "delay_minutes", "weekday_delays") }
      end
      def update
        @preference = ::Tasks::UpdateReminder.call(task: task, user: @actor, attributes: params.expect(reminder: [ :enabled, :delay_minutes, weekday_delays: {} ]))
        show
      end
      private
        def preference
          @preference ||= TaskReminderPreference.for_user(task: task, user: @actor)
        end
    end
  end
end
