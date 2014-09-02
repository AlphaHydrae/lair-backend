class SecurityController < Devise::OmniauthCallbacksController
  before_filter :generate_auth_csrf_token, only: [ :google_oauth2, :auth_failed, :auth_csrf_token ]

  def google_oauth2

    user = User.find_for_google_oauth2 request.env['omniauth.auth']
    return render json: { errors: [ { code: 'auth.notRegistered', message: 'You are not a registered user. Please contact the administrator.' } ] }, status: :unauthorized unless user.present?

    render json: { token: generate_auth_token(user) }
  end

  def new_session_path *args 
    users_auth_failed_path
  end

  def auth_failed
    render json: { errors: { code: 'auth.failure', message: 'Authentication failed.' } }, status: :unauthorized
  end

  def auth_csrf_token
    render nothing: true, status: :no_content
  end
end
