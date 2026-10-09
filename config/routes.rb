Rails.application.routes.draw do
  resources :households, only: %i[index new create show update] do
    resources :modules, only: %i[create destroy], controller: :household_modules, param: :key
    resources :tasks, except: :show do
      resource :reminder, only: %i[edit update], controller: :task_reminders
    end
    resources :memberships, only: :destroy
    resources :household_invitations, only: :create
    resource :integrations, only: %i[show create destroy] do
      post :replay
    end
  end
  get "household_invites/:token", to: "household_invitations#show", as: :household_invitation
  post "household_invites/:token", to: "household_invitations#accept"
  namespace :api do
    namespace :v1 do
      resources :households, only: :index do
        get "members", to: "households#members"
        resources :tasks, only: %i[index show create update destroy] do
          resource :reminder, only: %i[show update]
        end
        resources :occurrences, only: %i[index update]
        resources :pets, only: :index
      end
    end
  end
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :pets do
    resources :feeding_entries, only: %i[index create]
    resources :food_bags, only: %i[index new create] do
      patch :finish, on: :member
    end
    resource :qr_code, only: :show, controller: :qr_codes do
      get :download
      patch :regenerate
    end
    resources :weight_logs, except: :show
    resources :vaccines, except: :show
    resources :medical_entries, except: :show
  end

  get "feeding/:qr_token", to: "qr_meal_logs#show", as: :qr_meal_log
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
