require 'rails_helper'

RSpec.describe 'GET /api/ping' do

  it "returns pong" do
    get '/api/ping', nil, auth_headers
    expect(response.status).to eq(200)
    expect(response.body).to eq(JSON.dump('pong'))
  end
end
