class UserPolicy < ApplicationPolicy
  def create?
    admin?
  end

  def index?
    admin?
  end

  def show?
    admin?
  end

  def show_email?
    user == record || admin? || app?
  end

  def show_active?
    admin? || app?
  end

  def update?
    user == record || admin?
  end

  def update_email?
    admin?
  end

  def update_active?
    admin?
  end

  def update_roles?
    admin?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
