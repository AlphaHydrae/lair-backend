class MediaScanPolicy < ApplicationPolicy
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
      if user.admin?
        scope
      else
        scope.joins(:source).where('media_sources.user_id = ?', user.id)
      end
    end
  end
end
