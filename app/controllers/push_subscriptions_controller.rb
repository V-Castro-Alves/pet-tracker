class PushSubscriptionsController < ApplicationController
  def create
    subscription = Current.user.push_subscriptions.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    subscription.assign_attributes(
      user: Current.user,
      p256dh: subscription_params.dig(:keys, :p256dh),
      auth: subscription_params.dig(:keys, :auth),
      user_agent: request.user_agent
    )
    subscription.save!
    head :created
  end

  def destroy
    Current.user.push_subscriptions.find_by(endpoint: params.expect(:endpoint))&.destroy!
    head :no_content
  end

  private
    def subscription_params
      params.expect(push_subscription: [ :endpoint, { keys: %i[p256dh auth] } ])
    end
end
