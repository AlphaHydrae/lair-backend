module SpecAuthHelper
  def generate_auth_token token_user = nil
    token_user ||= user if respond_to?(:user)
    token_user ||= create :user
    AccessToken.new(token_user).encode
  end

  def generate_auth_headers user = nil
    { 'Authorization' => "Bearer #{generate_auth_token(user)}" }
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

RSpec.shared_examples "a protected resource" do
  let(:user){ create :user }

  it "should respond with HTTP 401 if no credentials are sent" do
    expect_no_changes{ protected_call.call({}) }
    expect_unauthorized
  end

  it "should respond with HTTP 401 if invalid credentials are sent" do
    expect_no_changes{ protected_call.call({ 'Authorization' => 'Foo Bar' }) }
    expect_unauthorized
  end

  it "should respond with HTTP 401 if the wrong type of credentials are sent" do
    expect_no_changes{ protected_call.call({ 'Authorization' => "Basic #{AccessToken.new(user).encode}" }) }
    expect_unauthorized
  end

  it "should respond with HTTP 401 if an invalid Bearer token is sent" do
    expect_no_changes{ protected_call.call({ 'Authorization' => "Bearer foo" }) }
    expect_unauthorized
  end

  # TODO: test invalid JWT signature, expired token, etc

  def expect_unauthorized
    expect(response.status).to eq(401)
  end
end
