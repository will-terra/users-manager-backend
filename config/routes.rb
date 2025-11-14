Rails.application.routes.draw do
  # Mount ActiveStorage routes for serving files and variants
  mount ActiveStorage::Engine => "/rails/active_storage"
  devise_for :users # Devise authentication endpoints

  # Simple health check for uptime monitoring
  get "/up", to: "up#index"

  # Mount Action Cable
  mount ActionCable.server => "/cable"

  namespace :api do
    namespace :v1 do
      # Authentication endpoints (JWT sessions & registration)
      post "sign_in",  to: "sessions#create"
      delete "sign_out", to: "sessions#destroy"
      post "sign_up",  to: "registrations#create"
      post "refresh_token", to: "sessions#refresh" # Refresh JWT token

      # Regular user-facing operations
      resources :users, only: [ :index, :show, :update, :destroy ] do
        member do
          patch :toggle_role # Allow role toggle (may be restricted by policy)
        end
        collection do
          get :profile # Current user profile summary
          # Allow clients to PATCH /api/v1/users/profile to update the
          # currently authenticated user's profile (including avatar uploads)
          # Map the PATCH to the `profile_update` action on the controller.
          patch :profile, action: :profile_update
        end
      end

      # Administrative endpoints
      namespace :admin do
        resources :imports, only: [ :index, :show, :create ]
        resources :users, only: [ :index, :show, :create, :update, :destroy ] do
          member do
            patch :toggle_role # Admin toggles another user's role
          end
          collection do
            get :overview # Aggregated overview of users
          end
        end
        get "stats", to: "stats#index" # System or usage statistics
        resources :imports, only: [ :create, :index, :show ] # Data import jobs
      end
    end
  end

  # Error handling routes
  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unprocessable_entity"
  get "/500", to: "errors#internal_server_error"

  # Catch all for undefined routes (but exclude rails/active_storage paths)
  match "*unmatched", to: "errors#not_found", via: :all, constraints: lambda { |req| !req.path.start_with?("/rails/active_storage") }
end
