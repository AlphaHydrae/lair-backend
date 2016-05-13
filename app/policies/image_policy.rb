class ImagePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end
