class OwnershipPolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def index?
    authenticated?
  end

  def update?
    authenticated?
  end

  def destroy?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
