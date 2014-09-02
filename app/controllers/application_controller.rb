class ApplicationController < ActionController::Base

  private

  def generate_auth_token user
    JWT.encode({ iss: user.email }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end

  def generate_auth_csrf_token
    state = SecureRandom.hex 32
    session['omniauth.state'] = state
    cookies['auth.csrfToken'] = state
  end
end
