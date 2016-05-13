class MediaSourcePolicy < ApplicationPolicy
  def create?
    authenticated? && (admin? || user == record.user)
  end

  def index?
    authenticated?
  end

  def show?
    admin? || user == record.user
  end

  def update?
    admin? || user == record.user
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope
      else
        scope.where 'media_sources.user_id = ?', user.id
      end
    end
  end
end
