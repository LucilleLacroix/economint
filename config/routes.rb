Rails.application.routes.draw do
  get 'goals/index'
  get 'goals/new'
  get 'goals/create'
  get 'goals/edit'
  get 'goals/update'
  get 'goals/destroy'
  get 'goals/add_money'
  get 'revenues/index'
  get 'revenues/show'
  get 'revenues/new'
  get 'revenues/edit'
  devise_for :users


  root to: "pages#home"
  get 'expenses_summary', to: 'pages#expenses_summary'

  resources :revenues do
    resources :categories, only: [:new, :create], defaults: { category_type: 'revenue' }
  end

  resources :expenses do
    resources :categories, only: [:new, :create], defaults: { category_type: 'expense' }
  end

  resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]

  resources :goals do
    post 'add_money', on: :member
  end
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
