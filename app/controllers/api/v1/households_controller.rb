module Api
  module V1
    class HouseholdsController < BaseController
      def index
        render json: paginate(households.order(:id))
      end
      def members
        render json: paginate(household.users.order(:id))
      end
    end
  end
end
