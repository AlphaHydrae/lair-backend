class LanguagePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
