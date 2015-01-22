Rails.application.routes.draw do

  get '/templates/:name', to: 'home#template'

  namespace :auth, module: nil do
    post '/google', to: 'security#google'
    post '/token', to: 'security#token'
  end

  mount Lair::API => '/api'

  get '/*path', to: 'home#index'
  root 'home#index'
end
