class HomeController < ApplicationController
  before_filter :generate_auth_csrf_token, only: :index

  def template

    raise 'Invalid template format' unless params[:format] == 'html'
    raise 'Invalid template path' unless params[:path].to_s.match /\A[a-z0-9\.\-\_]+(\/[a-z0-9\.\-\_]+)*\Z/

    template_logical_path = params[:path].sub /\.html$/, ''
    render template: "templates/#{template_logical_path}", layout: false
  end
end
