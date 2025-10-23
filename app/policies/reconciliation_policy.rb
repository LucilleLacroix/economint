class ReconciliationPolicy < ApplicationPolicy
  # Ces méthodes contrôlent les actions du contrôleur
  def new?
    user.present?
  end

  def analyze?
    user.present?
  end

  # 👇 La classe Scope sert uniquement à définir les règles pour les listes (index)
  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
