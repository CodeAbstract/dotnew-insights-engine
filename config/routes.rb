Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      constraints format: :json do
        resources :analytics, only: [] do
          collection do
            post :track
            post :end_visit
            get :stats
          end
        end
      end
    end
  end
end