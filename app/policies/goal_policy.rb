class GoalPolicy < ApplicationPolicy
 def show?
    user == record.user
  end

  def create?
    true
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end

  def add_money?
    record.user == user
  end
  
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
