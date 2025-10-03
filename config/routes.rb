Rails.application.routes.draw do
  devise_for :users


  root to: "pages#home"
  get 'expenses_summary', to: 'pages#expenses_summary'

  resources :revenues

  resources :expenses

  resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
