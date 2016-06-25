class MediaSearchPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def create?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
