class ItemPolicy < ApplicationPolicy
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

  class Scope < Scope
    def resolve
      scope
    end
  end
end
