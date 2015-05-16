class ImageSearchPolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def index?
    authenticated?
  end

  def show?
    authenticated?
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
