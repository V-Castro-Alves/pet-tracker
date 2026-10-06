module Api
  module V1
    class PetsController < BaseController
      def index
        raise ActiveRecord::RecordNotFound unless household.pets_enabled?
        render json: paginate(household.pets.order(:id))
      end
    end
  end
end
