require_dependency 'errors'

module ApiAuthenticationHelper

  def authenticate
    authenticate_with_header headers['Authorization'], required: false
  end

  def authenticate!
    authenticate_with_header headers['Authorization'], required: true
  end

  def authenticate_with_header authorization_header, options = {}

    if authorization_header.blank?
      fail_auth 'Missing credentials' if options.fetch :required, true
      return
    end

    return fail_auth 'Not a valid bearer token' unless m = authorization_header.match(/\ABearer (.+)\Z/)

    @raw_auth_token = m[1]

    begin
      token = JWT.decode @raw_auth_token, Rails.application.secrets.jwt_hmac_key
    rescue JWT::DecodeError
      @raw_auth_token = nil
      return fail_auth 'Invalid credentials'
    end

    @auth_token = token[0]
  end

  private

  def fail_auth message
    raise AuthError.new(message)
  end
end
