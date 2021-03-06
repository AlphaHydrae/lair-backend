require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  HOME_CONTROLLER_TEMPLATE_NOT_FOUND_RESPONSE = 'Template not found'

  %w(modules/home/home.template).each do |template|
    it "should render the #{template} template" do
      get :template, template: template, format: 'html'
      expect(response).to render_template(template)
    end
  end

  it "should not render unknown templates" do
    get :template, template: 'unknown', format: 'html'
    expect_template_not_found
  end

  it "should not render templates with the wrong extension" do
    get :template, template: 'home', format: 'txt'
    expect_template_not_found
  end

  it "should not render templates with invalid names" do
    %w(bad$characters bad/../name).each do |invalid_template|
      get :template, template: invalid_template, format: 'html'
      expect_template_not_found
    end
  end

  def expect_template_not_found
    expect(response.status).to eq(404)
    expect(response.body).to eq(HOME_CONTROLLER_TEMPLATE_NOT_FOUND_RESPONSE)
  end
end
