class MediaSearchPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def create?
    authenticated?
  end

  def update?
    admin? || (authenticated? && user == record.user)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
