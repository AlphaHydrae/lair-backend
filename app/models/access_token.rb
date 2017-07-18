class AccessToken
  attr_reader :user
  attr_accessor :scopes
  attr_accessor :expiration

  def initialize user, *scopes
    @user = user
    @scopes = scopes
    @expiration = 2.weeks.from_now
  end

  def encode
    raise 'Expiration invalid' if !@expiration.kind_of?(Time)

    JWT.encode({
      iss: @user.api_id,
      exp: @expiration.to_i,
      scopes: @scopes.collect(&:to_s)
    }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end
end
