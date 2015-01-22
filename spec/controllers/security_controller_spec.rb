require 'rails_helper'

RSpec.describe SecurityController, type: :controller do

  describe "POST #token" do
    let(:user){ create :user }

    it "should return the token used for authentication and user data" do

      token = user.generate_auth_token
      request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
      post :token

      expect(response.status).to eq(200)

      res = JSON.parse response.body
      expect(res).to eq({
        'token' => token,
        'user' => {
          'email' => user.email
        }
      })
    end

    it "should not return a token for an unauthorized user" do
      post :token
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)).to eq({
        'errors' => [
          { 'reason' => 'error', 'message' => 'Missing credentials' }
        ]
      })
    end
  end

=begin
TODO: write tests for google oauth2
  describe "POST google_oauth2" do
    let(:user){ create :user }

    it "should authenticate a user by e-mail" do

      @request.env['omniauth.auth'] = 'foo'
      allow(User).to receive(:find_for_google_oauth2).and_return(user)

      post :google_oauth2
      expect(response.status).to eq(200)

      res = JSON.parse response.body
      expect(res['token']).to be_a_kind_of(String)

      jwt = decode_auth_token res['token']
      expect(jwt).to eq({ 'iss' => user.email })
    end

    it "should regenerate the authentication anti-csrf token" do

      session['omniauth.state'] = 'foo'
      expect(session['omniauth.state']).to eq('foo')
      @request.env['omniauth.auth'] = 'bar'

      allow(User).to receive(:find_for_google_oauth2).and_return(user)
      expect(User).to receive(:find_for_google_oauth2).with('bar')

      post :google_oauth2
      expect(response.cookies['auth.csrfToken']).to match(/\A[a-z0-9]+\Z/)
      expect(session['omniauth.state']).to eq(response.cookies['auth.csrfToken'])
      expect(session['omniauth.state']).not_to eq('foo')
    end

    it "should not authenticate an unregistered user" do

      @request.env['omniauth.auth'] = 'foo'
      allow(User).to receive(:find_for_google_oauth2).and_return(nil)
      expect(User).to receive(:find_for_google_oauth2).with('foo')

      post :google_oauth2
      expect(response.status).to eq(401)
      # TODO: check error
    end
  end
=end
end
