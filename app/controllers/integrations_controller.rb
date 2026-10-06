class IntegrationsController < ApplicationController
  before_action :set_household
  def show
    @heartbeat = SchedulerHeartbeat.find_by(name: "household_scheduler")
    @tokens = @household.api_tokens.where(user: Current.user).order(created_at: :desc)
    @endpoints = @household.administered_by?(Current.user) ? @household.webhook_endpoints : WebhookEndpoint.none
    @deliveries = WebhookDelivery.where(webhook_endpoint: @endpoints).order(created_at: :desc).limit(50)
  end
  def create
    if params[:kind] == "token"
      _, @raw_token = ApiToken.issue!(household: @household, user: Current.user, name: params[:name], scopes: Array(params[:scopes]), expires_at: 90.days.from_now)
    else
      return head :forbidden unless @household.administered_by?(Current.user)
      endpoint = @household.webhook_endpoints.new(user: Current.user, url: params[:url])
      endpoint.save!
      @webhook_secret = endpoint.secret
    end
    response.headers["Cache-Control"] = "no-store"
    show
    render :show, status: :created
  rescue ActiveRecord::RecordInvalid => error
    redirect_to household_integrations_path(@household), alert: error.record.errors.full_messages.to_sentence
  end
  def destroy
    if params[:kind] == "token"
      @household.api_tokens.where(user: Current.user).find(params[:record_id]).update!(revoked_at: Time.current)
    else
      return head :forbidden unless @household.administered_by?(Current.user)
      @household.webhook_endpoints.find(params[:record_id]).update!(active: false)
    end
    redirect_to household_integrations_path(@household)
  end
  def replay
    return head :forbidden unless @household.administered_by?(Current.user)
    delivery = WebhookDelivery.where(webhook_endpoint: @household.webhook_endpoints).find(params[:delivery_id])
    delivery.with_lock { delivery.update!(attempts: 0, delivered_at: nil, next_attempt_at: nil) }
    WebhookDeliveryJob.perform_later(delivery)
    redirect_to household_integrations_path(@household)
  end
  private
    def set_household
      @household = Current.user.households.find_by!(public_id: params[:household_id])
    end
end
