Rails.application.routes.draw do
  resource :session
  resources :registrations, only: [ :new, :create ]
  resources :passwords, param: :token
  get "home/index"
  get "auth/:provider/callback", to: "app/authentication_providers#create"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :internal do
      resources :users, only: [ :create ]
    end
  end

  namespace :app do
    resources :dashboard, only: [ :index ]
    resources :wordpress_websites, only: [ :index, :new, :create ]
    resources :wordpress_contents do
      member do
        patch :publish
        get :publish_modal
      end
      collection do
        get :close_modal
      end
    end
    resources :authentication_providers, only: [ :destroy ]
    resources :prompts, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :domains, only: [ :index, :new, :create, :destroy ]
    resources :keywords, only: [ :index ]
    resources :bulk_wordpress_content_generations, only: [ :new, :create ]
    resources :linkedin_contents do
      member do
        patch :publish
        get :publish_modal
      end
    end
    root "dashboard#index"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  resources :pages, only: [ :show ], path: "/"
  root "home#index"
end
