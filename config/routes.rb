require 'resque/server'

Rails.application.routes.draw do

  resque_web_constraint = lambda do |request|
    #current_user = request.env['warden'].user
    #current_user.present? && current_user.respond_to?(:is_admin?) && current_user.is_admin?
    true
  end

  constraints resque_web_constraint do
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
