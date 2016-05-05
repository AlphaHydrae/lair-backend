require_dependency 'errors'

module ApiAuthenticationHelper
  def current_user

    new_user = false

    if @auth_token && !@current_user
      new_user = true
      @current_user = User.where(api_id: @auth_token['iss']).first
      raise AuthError.new("Unknown user #{@auth_token['iss']}") if @current_user.blank?
    end

    if @current_user
      raise AuthError.new("User #{@current_user.api_id} is inactive") unless @current_user.active?
    end

    User.where(id: @current_user.id).update_all(active_at: Time.now) if @current_user && new_user

    @current_user
  end

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
