class ScrapPolicy < ApplicationPolicy
  def show?
    admin?
  end
end
