class SecurityController < ApplicationController
  include ApiAuthenticationHelper

  def token
    authenticate_with_header request.headers['Authorization']
    render json: { token: @raw_auth_token, user: { email: @auth_token['iss'] } }
  end

  def google

    client_id = Rails.application.secrets.google_oauth2_client_id

    token_request = {
      code: params[:code],
      client_id: client_id,
      client_secret: Rails.application.secrets.google_oauth2_client_secret,
      redirect_uri: params[:redirectUri],
      grant_type: 'authorization_code'
    }

    Rails.logger.debug "Requesting Google OAuth2 access token for client #{client_id}"

    res = HTTParty.post GOOGLE_ACCESS_TOKEN_URL, body: token_request

    if res.code != 200

      message = begin
        JSON.parse(res.body)['error']
      rescue
        'unknown error'
      end

      Rails.logger.warn "An error occurred while authenticating with Google: #{message}"
      return render json: { errors: [ { code: 'auth.error', message: 'An error occurred while authenticating with Google.' } ] }, status: :unauthorized
    end

    token = JSON.parse res.body
    access_token = token['access_token']

    Rails.logger.debug "Requesting user information from Google People API"

    res = HTTParty.get GOOGLE_PEOPLE_API_URL, headers: { 'Authorization' => "Bearer #{access_token}" }

    if res.code != 200
      # TODO: log message from people api error
      return render json: { errors: [ { code: 'auth.error', message: 'An error occurred while authenticating with Google.' } ] }, status: :unauthorized
    end

    profile = JSON.parse res.body

    user = User.where(email: profile['email']).first

    unless user.present?
      return render json: { errors: [ { code: 'auth.notRegistered', message: 'You are not a registered user. Please contact the administrator.' } ] }, status: :unauthorized
    end

    User.increment_counter :sign_in_count, user.id

    render json: { token: user.generate_auth_token, user: { email: user.email } }
  end

  private

  GOOGLE_ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token'
  GOOGLE_PEOPLE_API_URL = 'https://www.googleapis.com/plus/v1/people/me/openIdConnect'
end
