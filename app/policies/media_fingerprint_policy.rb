class MediaFingerprintPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
