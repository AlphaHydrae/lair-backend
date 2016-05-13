class AccessTokenPolicy < ApplicationPolicy
  def create?
    authenticated?
  end
end
