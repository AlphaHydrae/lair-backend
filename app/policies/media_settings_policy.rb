class MediaSettingsPolicy < ApplicationPolicy
  def show?
    authenticated?
  end

  def update?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope.where user_id: user.id
    end
  end
end
