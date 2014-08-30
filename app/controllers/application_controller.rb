class ApplicationController < ActionController::Base

  private

  def generate_auth_csrf_token
    state = SecureRandom.hex 32
    session['omniauth.state'] = state
    cookies['auth.csrfToken'] = state
  end
end
