class User < ActiveRecord::Base
  include ResourceWithIdentifier
  before_create :set_identifier
  # TODO: add tracking information about logins

  validates :email, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false }

  def generate_auth_token expiration = 2.weeks.from_now
    JWT.encode({ iss: email, exp: expiration.to_i }, Rails.application.secrets.jwt_hmac_key, 'HS512')
  end
end
