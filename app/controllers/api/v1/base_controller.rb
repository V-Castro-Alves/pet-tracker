module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :require_authentication
      prepend_before_action :authenticate_api
      skip_forgery_protection if: -> { @api_token.present? }
      before_action :authorize_scope
      before_action -> { household if params[:household_id].present? }
      around_action :idempotent_mutation
      rescue_from ActiveRecord::StatementInvalid do |error|
        raise error unless error.cause.is_a?(SQLite3::BusyException)
        render_error("busy", "Another request is being saved. Retry with the same idempotency key.", :conflict)
      end
      rescue_from ActiveRecord::RecordNotFound, with: -> { render_error("not_found", "Resource not found", :not_found) }
      rescue_from ActiveRecord::RecordInvalid, with: ->(error) { render_error("validation_failed", error.record.errors.full_messages.join(", "), :unprocessable_entity) }
      rescue_from ActionController::ParameterMissing, ArgumentError, with: ->(error) { render_error("invalid_request", error.message, :unprocessable_entity) }
      rescue_from ActionController::InvalidAuthenticityToken, with: -> { render_error("invalid_csrf_token", "Refresh the page and try again", :unprocessable_entity) }
      rescue_from Tasks::Resolve::Conflict, with: ->(error) { render_error("conflict", error.message, :conflict) }
      private
        def authenticate_api
          if request.headers["Authorization"].present?
            raw = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
            @api_token = ApiToken.authenticate(raw)
            @actor = @api_token&.user
          else
            resume_session
            @actor = Current.user
          end
          render_error("unauthorized", "Sign in or provide a valid bearer token", :unauthorized) unless @actor
        end
        def authorize_scope
          return unless @api_token
          required = if controller_name == "reminders" && !request.get?
            "reminders:write"
          elsif controller_name == "pets"
            "pets:read"
          else
            request.get? ? "tasks:read" : "tasks:write"
          end
          render_error("forbidden", "Token lacks #{required}", :forbidden) unless @api_token.scopes.include?(required)
        end
        def households
          scope = @actor.households
          @api_token ? scope.where(id: @api_token.household_id) : scope
        end
        def household
          @household ||= households.find_by!(public_id: params[:household_id])
        end
        def task
          @task ||= household.tasks.find_by!(public_id: params[:task_id] || params[:id])
        end
        def render_error(code, message, status)
          render json: { error: { code: code, message: message } }, status: status
        end
        def paginate(scope)
          page = [ params.fetch(:page, 1).to_i, 1 ].max
          { data: scope.limit(50).offset((page - 1) * 50).map { |record| serialize(record) }, page: page, per_page: 50 }
        end
        def serialize(record)
          case record
          when Household
            { id: record.public_id, name: record.name, time_zone: record.time_zone, modules: record.household_modules.pluck(:key) }
          when Task
            detail = record.pet_care_task_detail
            record.attributes.slice("title", "notes", "category", "kind", "recurrence", "starts_on", "local_time", "weekdays", "time_zone", "archived_at").merge(id: record.public_id, assignee_id: record.assignee&.public_id, pet_id: detail&.pet&.public_id, care_type: detail&.care_type, amount_g: detail&.amount_g)
          when TaskOccurrence
            { id: record.public_id, task_id: record.task.public_id, title: record.task.title, scheduled_at: record.scheduled_at.iso8601, status: record.status, assignee_id: record.assignee&.public_id, actor_id: record.actor&.public_id, credited_user_id: record.credited_user&.public_id, resolved_at: record.resolved_at&.iso8601 }
          when User
            { id: record.public_id, name: record.name }
          when Pet
            { id: record.public_id, name: record.name, species: record.species, time_zone: record.time_zone }
          end
        end
        def idempotent_mutation
          return yield if request.get? || request.head?
          key = request.headers["Idempotency-Key"]
          return render_error("idempotency_key_required", "Provide an Idempotency-Key header (maximum 200 characters)", :bad_request) if key.blank? || key.length > 200
          fingerprint = Digest::SHA256.hexdigest([ request.method, request.fullpath, request.raw_post, @api_token&.id ].join("\n"))
          @actor.with_lock do
            existing = ApiRequest.find_by(user: @actor, key: key)
            if existing
              return render_error("idempotency_conflict", "Key was used for a different request", :conflict) unless existing.fingerprint == fingerprint
              return render body: existing.response_body, content_type: "application/json", status: existing.response_status
            end
            yield
            ApiRequest.create!(user: @actor, key: key, fingerprint: fingerprint, response_status: response.status, response_body: response.body)
          end
        end
    end
  end
end
