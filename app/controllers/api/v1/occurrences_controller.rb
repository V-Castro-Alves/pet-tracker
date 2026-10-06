module Api
  module V1
    class OccurrencesController < BaseController
      def index
        scope = TaskOccurrence.where(task: household.tasks).order(:scheduled_at, :id)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(assignee: household.users.find_by!(public_id: params[:assignee_id])) if params[:assignee_id].present?
        scope = scope.where("scheduled_at >= ?", Time.iso8601(params[:from])) if params[:from].present?
        scope = scope.where("scheduled_at < ?", Time.iso8601(params[:to])) if params[:to].present?
        render json: paginate(scope)
      end
      def update
        occurrence = TaskOccurrence.where(task: household.tasks).find_by!(public_id: params[:id])
        attrs = params.expect(occurrence: [ :status, :credited_user_id, :actual_amount_g ])
        credited = attrs[:credited_user_id].present? ? household.users.find_by!(public_id: attrs[:credited_user_id]) : @actor
        ::Tasks::Resolve.call(occurrence: occurrence, actor: @actor, status: attrs[:status], credited_user: credited, amount: attrs[:actual_amount_g])
        render json: { data: serialize(occurrence) }
      end
    end
  end
end
