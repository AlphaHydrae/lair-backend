class ImagePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def update?
    authenticated?
  end

  def destroy?
    authenticated?
  end
end
