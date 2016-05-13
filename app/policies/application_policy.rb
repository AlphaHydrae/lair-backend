class ApplicationPolicy
  attr_reader :user, :token, :record, :params

  def initialize user, record
    @user = user
    @record = record

    if user.kind_of? UserContext
      @user_context = user
      @user = user.user
      @token = user.token
      @params = user.params
    end
  end

  def create?
    false
  end

  def index?
    false
  end

  def show?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def authenticated?
    raise AuthError.new('Missing credentials') unless user
    true
  end

  def admin?
    role? :admin
  end

  def app?
    user == :app
  end

  def role? role
    user.kind_of?(User) && user.try("#{role}?".to_sym)
  end

  def user_context
    @user_context ? @user_context : UserContext.new(@user, @token, @params)
  end

  def scope
    Pundit.policy_scope! user, record.class
  end

  def serializer
    serializer_class = "#{@record.class.name}Serializer".constantize rescue nil
    raise NameError, "unable to find serializer `#{@record.class.name}Serializer`" unless serializer_class
    serializer_class.new self
  end

  class Scope
    attr_reader :user, :token, :scope, :params

    def initialize user, scope
      @user = user
      @scope = scope

      if user.kind_of? UserContext
        @user_context = user
        @user = user.user
        @token = user.token
        @params = user.params
      end
    end

    def resolve
      scope
    end
  end
end
