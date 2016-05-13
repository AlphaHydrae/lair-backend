class AccessToken
  def initialize user
    @user = user
    @expiration = 2.weeks.from_now
  end

  def encode
    JWT.encode({ iss: @user.api_id, exp: @expiration.to_i }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end
end
