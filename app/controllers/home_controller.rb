class HomeController < ApplicationController
  append_view_path Rails.root.join('client')

  def template

    # only accept html templates
    return render_template_not_found unless params[:format] == 'html'

    # only accept alphanumeric characters, hyphens and underscores, separated by slashes
    return render_template_not_found unless params[:template].to_s.match /\A[a-z0-9\.\-\_]+(\/[a-z0-9\.\-\_]+)*\Z/i

    if params[:template].to_s.match /^modules\//
      begin
        return render template: params[:template].to_s, layout: false
      rescue ActionView::MissingTemplate
        return render_template_not_found
      end
    end

    begin
      render template: "templates/#{params[:template]}", layout: false
    rescue ActionView::MissingTemplate
      render_template_not_found
    end
  end

  private

  def render_template_not_found
    render text: 'Template not found', status: :not_found
  end
end
