class MediaScanFilePolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def index?
    authenticated?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.media_manager?
        scope
      else
        scope.joins(scan: :source).where('media_sources.user_id = ?', user.id)
      end
    end
  end
end
