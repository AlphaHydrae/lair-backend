Rails.application.routes.draw do

  devise_for :users, skip: [:sessions], controllers: { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get '/users/auth/failed', to: 'users/omniauth_callbacks#auth_failed'
  end

  get '/templates/*path', to: 'home#template'

  mount Lair::API => '/api'

  root 'home#index'
end
