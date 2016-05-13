class MediaUrlPolicy < ApplicationPolicy
  def resolve?
    admin?
  end

  def create?
    admin?
  end

  def index?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
