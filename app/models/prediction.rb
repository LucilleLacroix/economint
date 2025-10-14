class Prediction < ApplicationRecord
  belongs_to :user

  validates :scenario_name, presence: true

  # Génère la prévision sur une période donnée
  def generate_forecast(start_date, end_date)
    forecast = { "categories" => {}, "totals" => {} }

    expense_categories = user.categories.where(category_type: "expense")
    income_categories  = user.categories.where(category_type: "income")

    total_expenses = { pessimiste: 0, realiste: 0, optimiste: 0 }
    total_incomes  = { pessimiste: 0, realiste: 0, optimiste: 0 }

    # Dépenses
    expense_categories.each do |category|
      total_expense = user.expenses.where(category_id: category.id, date: start_date..end_date).sum(:amount)
      total_expense = historical_average(user.expenses.where(category_id: category.id), start_date, end_date) if total_expense.zero?

      pessimiste = (total_expense * 1.2).round(2)
      realiste   = total_expense.round(2)
      optimiste  = (total_expense * 0.8).round(2)

      forecast["categories"][category.name] = {
        "type" => "expense",
        "pessimiste" => pessimiste,
        "realiste"   => realiste,
        "optimiste"  => optimiste
      }

      total_expenses[:pessimiste] += pessimiste
      total_expenses[:realiste]   += realiste
      total_expenses[:optimiste]  += optimiste
    end

    # Revenus
    income_categories.each do |category|
      total_income = user.revenues.where(category_id: category.id, date: start_date..end_date).sum(:amount)
      total_income = historical_average(user.revenues.where(category_id: category.id), start_date, end_date) if total_income.zero?

      pessimiste = (total_income * 0.9).round(2)
      realiste   = total_income.round(2)
      optimiste  = (total_income * 1.1).round(2)

      forecast["categories"][category.name] = {
        "type" => "income",
        "pessimiste" => pessimiste,
        "realiste"   => realiste,
        "optimiste"  => optimiste
      }

      total_incomes[:pessimiste] += pessimiste
      total_incomes[:realiste]   += realiste
      total_incomes[:optimiste]  += optimiste
    end

    # Totaux
    forecast["totals"] = {
      "pessimiste" => (total_incomes[:pessimiste] - total_expenses[:pessimiste]).round(2),
      "realiste"   => (total_incomes[:realiste] - total_expenses[:realiste]).round(2),
      "optimiste"  => (total_incomes[:optimiste] - total_expenses[:optimiste]).round(2)
    }

    forecast.merge!("start_date" => start_date, "end_date" => end_date)
  end

  private

  # Moyenne historique si pas de données sur la période
  def historical_average(scope, start_date, end_date)
    total = scope.sum(:amount)
    min_date = scope.minimum(:date)
    max_date = scope.maximum(:date)
    months_count = [(max_date && min_date) ? ((max_date - min_date).to_i / 30.0).round : 1, 1].max
    (total / months_count * ((end_date - start_date).to_i / 30.0)).round(2)
  end
end
