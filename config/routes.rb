Rails.application.routes.draw do

  devise_for :users, skip: [ :sessions ], controllers: { omniauth_callbacks: 'security' }

  devise_scope :user do
    get '/users/auth/failed', to: 'security#auth_failed'
    post '/users/auth/start', to: 'security#auth_csrf_token'
  end

  get '/templates/:name', to: 'home#template'

  mount Lair::API => '/api'

  get '/*path', to: 'home#index'
  root 'home#index'
end
