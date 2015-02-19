require_dependency 'errors'

module ApiAuthenticationHelper

  def authenticate_with_header authorization_header, options = {}

    return fail_authentication 'Missing credentials', options if authorization_header.blank?
    return fail_authentication 'Wrong credentials', options unless m = authorization_header.match(/\ABearer ([a-zA-Z0-9\-\_\/\:\=\.]+)\Z/)

    @raw_auth_token = m[1]

    begin
      token = JWT.decode @raw_auth_token, Rails.application.secrets.jwt_hmac_key
    rescue JWT::DecodeError
      @raw_auth_token = nil
      return fail_authentication 'Wrong credentials', options
    end

    @auth_token = token[0]
  end

  def fail_authentication message, options = {}
    raise AuthError.new(message) if options.fetch(:required, true)
  end
end
