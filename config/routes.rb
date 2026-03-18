Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # 1. User faz upload do CV → ClaudeAnalyser processa → mostra 3 roles sugeridos
  resources :analyses, only: [:new, :create, :show]

  # 2. User vê detalhes de um role sugerido e inicia entrevista
  resources :suggested_roles, only: [:show] do
    resources :interview_sessions, only: [:new, :create]
  end

  # 3. Sessão de entrevista em andamento → user responde perguntas + results
  resources :interview_sessions, only: [:show, :update] do
    resources :interview_answers, only: [:create]
    get :results, on: :member
  end

  get "dashboard", to: "pages#dashboard", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check
end
