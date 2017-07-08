require 'resque/server'

Rails.application.routes.draw do

  # FIXME: deploy resque web separately in production
  if Rails.env == 'development'
    mount ResqueWeb::Engine => '/resque'
  end

  namespace :auth, module: nil do
    post '/google', to: 'security#google'
    post '/token', to: 'security#token' # TODO: move this to API
  end

  mount Lair::API => '/api'

  if %w(development test).include? Rails.env
    get '/templates/*template', to: 'home#template'
  end

  get '/*path', to: 'home#index'
  root 'home#index'
end
