class MediaAbstractFilePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  class Scope < Scope
    def resolve
      if user.try :admin?
        scope.joins source: :user
      elsif user
        scope.joins(source: :user).where 'media_sources.user_id = ?', user.id
      end
    end
  end
end
