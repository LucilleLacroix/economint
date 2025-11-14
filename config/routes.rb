Rails.application.routes.draw do
  get 'bankin/connect'
  get 'bankin/callback'

  devise_for :users


  root to: "pages#home"
  get 'expenses_summary', to: 'pages#expenses_summary'

  resources :revenues do
    resources :categories, only: [:new, :create], defaults: { category_type: 'revenue' }
  end

  resources :expenses, except: [:show]do
    resources :categories, only: [:new, :create], defaults: { category_type: 'expense' }
  end

  resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]

  resources :goals do
    post 'add_money', on: :member
  end

  resources :predictions

  resources :budgets, only: [:index, :new, :create, :edit, :update, :destroy]

  resources :reconciliations, only: [:index, :new, :create, :show, :destroy] do
    post :validate_match, on: :member
  end
  get "bankin/connect", to: "bankin#connect"
  get "bankin/callback", to: "bankin#callback"



  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
