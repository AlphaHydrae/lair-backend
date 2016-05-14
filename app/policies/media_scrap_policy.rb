class MediaScrapPolicy < ApplicationPolicy
  def show?
    admin?
  end

  def update?
    admin?
  end

  def retry?
    admin?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
