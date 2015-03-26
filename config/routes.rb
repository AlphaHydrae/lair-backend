require 'resque/server'

Rails.application.routes.draw do
  namespace :auth, module: nil do
    post '/google', to: 'security#google'
    post '/token', to: 'security#token'
  end

  mount Lair::API => '/api'

  if %w(development test).include? Rails.env
    mount Resque::Server.new, at: '/resque'
    get '/templates/:name', to: 'home#template'
  end

  get '/*path', to: 'home#index'
  root 'home#index'
end
