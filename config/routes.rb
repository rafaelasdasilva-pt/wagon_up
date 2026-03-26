Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  root to: "pages#home"

  get "dashboard", to: "pages#dashboard", as: :dashboard

  # 1. User faz upload do CV → ClaudeAnalyser processa → mostra roles sugeridos
  resources :analyses, only: [:index, :new, :create, :show]

  # 2. User vê detalhes de um role e inicia entrevista
  resources :roles, only: [:show] do
    get :cv, on: :member
    resources :interviews, only: [:new, :create]
  end

  # 3. Entrevista em curso → user responde → vê resultados
  resources :interviews, only: [:show, :update] do
    resources :answers, only: [:create]
    get :results, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
