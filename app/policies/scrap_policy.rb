class ScrapPolicy < ApplicationPolicy
  def show?
    admin?
  end

  def update?
    admin?
  end
end
