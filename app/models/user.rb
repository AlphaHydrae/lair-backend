class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :trackable, :omniauth_providers => [:google_oauth2]

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def self.find_for_google_oauth2 omniauth_auth
    User.where(email: omniauth_auth.info[:email]).first
  end
end
