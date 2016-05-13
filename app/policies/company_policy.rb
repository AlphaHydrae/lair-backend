class CompanyPolicy < ApplicationPolicy
  def create?
    authenticated?
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
