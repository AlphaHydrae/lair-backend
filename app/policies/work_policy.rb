class WorkPolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def index?
    true
  end

  def show?
    true
  end

  def update?
    authenticated?
  end

  def destroy?
    admin?
  end

  def hard_destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
