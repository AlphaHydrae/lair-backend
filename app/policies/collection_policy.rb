class CollectionPolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def index?
    true
  end

  def show?
    authenticated? || record.public_access
  end

  def update?
    authenticated?
  end

  def destroy?
    authenticated?
  end

  class Scope < Scope
    def resolve
      if user.try :admin?
        scope
      elsif user
        scope.where 'public_access = true OR creator_id = ?', user.id
      else
        scope.where public_access: true
      end
    end
  end
end
