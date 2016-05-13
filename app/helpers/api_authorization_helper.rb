module ApiAuthorizationHelper
  def authorize! record, query
    query = "#{query}?" unless query.to_s.last == '?'
    Pundit.authorize pundit_user, record, query
  end

  def policy subject, user = nil
    Pundit.policy! user || pundit_user, subject
  end

  def policy_scope subject, user = nil
    Pundit.policy_scope! user || pundit_user, subject
  end

  def policy_serializer subject, user = nil
    policy(subject, user).serializer
  end

  def pundit_user
    UserContext.new current_user, @auth_token, params
  end
end
