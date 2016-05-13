require 'rails_helper'

RSpec.describe 'POST /api/companies' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }

  let :minimal_company do
    {
      name: '20th Century Fox'
    }
  end

  let :full_company do
    minimal_company.merge({
    })
  end

  let(:protected_call){ ->(h){ post '/api/companies', JSON.dump(minimal_company), h.merge('CONTENT_TYPE' => 'application/json') } }
  it_behaves_like "a protected resource"

  it "should create a minimal company" do
    expect_changes events: 1, companies: 1 do
      post_company minimal_company
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_company)

    company = expect_company json, creator: user
    expect_model_event :create, user, company
  end

  it "should create a full company" do
    expect_changes events: 1, companies: 1 do
      post_company full_company
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(full_company)

    company = expect_company json, creator: user
    expect_model_event :create, user, company
  end

  def post_company body
    post '/api/companies', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
