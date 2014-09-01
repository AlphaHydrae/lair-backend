
module SpecAuthHelper

  def auth_token user = nil
    user ||= create :user
    JWT.encode({ iss: user.email }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end

  def auth_headers user = nil
    { 'Authorization' => "Bearer #{auth_token(user)}" }
  end
end
