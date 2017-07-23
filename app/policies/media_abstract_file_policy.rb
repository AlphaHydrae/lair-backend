class MediaAbstractFilePolicy < ApplicationPolicy
  def index?
    admin? || media_manager?
  end

  def show?
    admin? || user == record.source.user
  end

  def analysis?
    admin? || media_manager? || user == record.source.user
  end

  class Scope < Scope
    def resolve
      new_scope = scope.joins source: :user
      if user.admin?
        new_scope
      else
        new_scope.where 'media_sources.user_id = ?', user.id
      end
    end
  end
end
