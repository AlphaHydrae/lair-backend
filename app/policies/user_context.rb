class UserContext
  attr_reader :user, :token, :params

  def initialize user, token, params
    @user = user
    @token = token
    @params = params
  end
end
