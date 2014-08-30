class HomeController < ApplicationController
  before_filter :generate_auth_csrf_token, only: :index
end
