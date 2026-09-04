class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    def current_user_pet!(identifier = params[:pet_id] || params[:id])
      scope = Current.user.pets
      scope.find_by(public_id: identifier) || (scope.find_by(id: identifier) if identifier.to_s.match?(/\A\d+\z/)) || raise(ActiveRecord::RecordNotFound)
    end
end
