module Api
  module V1
    class TasksController < BaseController
      include TaskParameters
      def index
        render json: paginate(household.tasks.active.order(:id))
      end
      def show
        render json: { data: serialize(task) }
      end
      def create
        record = household.tasks.new(time_zone: household.time_zone)
        ::Tasks::Save.call(task: record, attributes: task_attributes(household))
        render json: { data: serialize(record) }, status: :created
      end
      def update
        ::Tasks::Save.call(task: task, attributes: task_attributes(household))
        render json: { data: serialize(task) }
      end
      def destroy
        ::Tasks::Save.archive(task)
        render json: { data: serialize(task) }
      end
    end
  end
end
