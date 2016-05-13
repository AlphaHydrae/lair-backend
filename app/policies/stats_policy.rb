class StatsPolicy < ApplicationPolicy
  def images?
    admin?
  end
end
