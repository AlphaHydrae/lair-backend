class OwnershipPolicy < ApplicationPolicy
  def create?
    authenticated? && (admin? || user == record.user)
  end

  def index?
    authenticated?
  end

  def update?
    authenticated? && (admin? || user == record.user)
  end

  def update_user?
    admin?
  end

  def destroy?
    admin? || user == record.user
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
