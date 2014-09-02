
module SpecAuthHelper

  def auth_token user = nil
    user ||= create :user
    JWT.encode({ iss: user.email }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end

  def auth_headers user = nil
    { 'Authorization' => "Bearer #{auth_token(user)}" }
  end

  def decode_auth_token token

    decoded = nil
    expect{ decoded = JWT.decode token, Rails.application.secrets.jwt_hmac_key }.not_to raise_error

    expect(decoded).to be_a_kind_of(Array)
    expect(decoded.length).to eq(2)
    expect(decoded[1]).to eq({ 'typ' => 'JWT', 'alg' => 'HS512' })

    decoded[0]
  end
end
