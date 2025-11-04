class ReconciliationPolicy < ApplicationPolicy
  def new?
    user.present?
  end

  def create?
    user.present?
  end

  def show?
    user.present? && record.user == user
  end

  def destroy?
    user.present? && record.user == user
  end
  
  def validate_match?
    user.present? && record.user == user
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
