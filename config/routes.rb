Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :pets do
    resources :meal_slots, except: :show
    resources :meal_logs, only: %i[index new create]
    resources :food_bags, only: %i[index new create] do
      patch :finish, on: :member
    end
    resource :qr_code, only: :show, controller: :qr_codes do
      get :download
      patch :regenerate
    end
    resources :pet_users, only: %i[index destroy]
    resources :pet_invites, only: %i[create destroy]
    resources :weight_logs, except: :show
    resources :vaccines, except: :show
    resources :medical_entries, except: :show
  end

  get "meal_log/:qr_token", to: "qr_meal_logs#show", as: :qr_meal_log
  get "invites/:token", to: "invitations#show", as: :invitation
  post "invites/:token", to: "invitations#create"
  resources :notifications, only: %i[index update] do
    patch :read_all, on: :collection
  end
  resources :push_subscriptions, only: %i[create destroy]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#show"
end
