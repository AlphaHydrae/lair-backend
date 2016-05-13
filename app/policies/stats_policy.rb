class StatsPolicy < ApplicationPolicy
  def images?
    authenticated?
  end
end
