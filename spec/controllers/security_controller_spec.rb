require 'rails_helper'

RSpec.describe SecurityController, type: :controller do

  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

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

  describe "POST auth_csrf_token" do

    it "should generate an authentication anti-csrf token and store it in the session" do
      post :auth_csrf_token
      expect(response.status).to eq(204)
      expect(response.cookies['auth.csrfToken']).to match(/\A[a-z0-9]+\Z/)
      expect(session['omniauth.state']).to eq(response.cookies['auth.csrfToken'])
    end

    it "should regenerate the authentication anti-csrf token" do

      session['omniauth.state'] = 'foo'
      expect(session['omniauth.state']).to eq('foo')

      post :auth_csrf_token
      expect(response.cookies['auth.csrfToken']).to match(/\A[a-z0-9]+\Z/)
      expect(session['omniauth.state']).to eq(response.cookies['auth.csrfToken'])
      expect(session['omniauth.state']).not_to eq('foo')
    end
  end

  describe "GET auth_failed" do

    it "should return an error indicating that authentication has failed" do
      get :auth_failed
      expect(response.status).to eq(401)
      # TODO: check error
    end

    it "should regenerate the authentication anti-csrf token" do

      session['omniauth.state'] = 'foo'
      expect(session['omniauth.state']).to eq('foo')

      get :auth_failed
      expect(response.cookies['auth.csrfToken']).to match(/\A[a-z0-9]+\Z/)
      expect(session['omniauth.state']).to eq(response.cookies['auth.csrfToken'])
      expect(session['omniauth.state']).not_to eq('foo')
    end
  end

  describe "#new_session_path" do

    it "should redirect to users_auth_failed" do
      expect(controller.new_session_path).to eq(users_auth_failed_path)
    end
  end
end
