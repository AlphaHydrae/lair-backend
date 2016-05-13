class MediaScanPolicy < ApplicationPolicy
  def create?
    authenticated?
  end

  def update?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
