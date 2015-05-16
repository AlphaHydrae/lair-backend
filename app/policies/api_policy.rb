class ApiPolicy < ApplicationPolicy
  def ping?
    authenticated?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
