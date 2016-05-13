require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  let(:user){ create :user }
  subject{ described_class.new user }

  it "should generate a JWT token that can be used to authenticate the user" do
    token = subject.encode
    decoded_token = JWT.decode token, Rails.application.secrets.jwt_hmac_key
    expect(2.weeks.from_now.to_i - decoded_token[0]['exp']).to be <= 5
    expect(decoded_token[0]['iss']).to eq(user.api_id)
  end
end
