class Prediction < ApplicationRecord
  belongs_to :user

  validates :scenario_name, presence: true

  attr_accessor :selected_category_ids

  # Generate forecast for a period
  def generate_forecast(start_date, end_date)
    forecast = { "categories" => {}, "totals" => {} }

    expense_categories  = user.categories.for_expenses
    revenue_categories  = user.categories.for_revenues

    # Filter by selected categories if any
    if selected_category_ids.present? && selected_category_ids.any?
      expense_categories = expense_categories.where(id: selected_category_ids)
      revenue_categories = revenue_categories.where(id: selected_category_ids)
    end

    total_expenses  = { "pessimiste" => 0, "realiste" => 0, "optimiste" => 0 }
    total_revenues  = { "pessimiste" => 0, "realiste" => 0, "optimiste" => 0 }

    # Expenses
    expense_categories.each do |category|
      total_expense = user.expenses.where(category_id: category.id, date: start_date..end_date).sum(:amount)
      total_expense = historical_average(user.expenses.where(category_id: category.id), start_date, end_date) if total_expense.zero?

      forecast["categories"][category.name] = {
        "type"       => "expense",
        "pessimiste" => (total_expense * 1.2).round(2),
        "realiste"   => total_expense.round(2),
        "optimiste"  => (total_expense * 0.8).round(2)
      }

      total_expenses["pessimiste"] += (total_expense * 1.2).round(2)
      total_expenses["realiste"]   += total_expense.round(2)
      total_expenses["optimiste"]  += (total_expense * 0.8).round(2)
    end

    # Revenues
    revenue_categories.each do |category|
      total_revenue = user.revenues.where(category_id: category.id, date: start_date..end_date).sum(:amount)
      total_revenue = historical_average(user.revenues.where(category_id: category.id), start_date, end_date) if total_revenue.zero?

      forecast["categories"][category.name] = {
        "type"       => "revenue",
        "pessimiste" => (total_revenue * 0.9).round(2),
        "realiste"   => total_revenue.round(2),
        "optimiste"  => (total_revenue * 1.1).round(2)
      }

      total_revenues["pessimiste"] += (total_revenue * 0.9).round(2)
      total_revenues["realiste"]   += total_revenue.round(2)
      total_revenues["optimiste"]  += (total_revenue * 1.1).round(2)
    end

    # Totals
    forecast["totals"] = {
      "pessimiste" => (total_revenues["pessimiste"] - total_expenses["pessimiste"]).round(2),
      "realiste"   => (total_revenues["realiste"]   - total_expenses["realiste"]).round(2),
      "optimiste"  => (total_revenues["optimiste"]  - total_expenses["optimiste"]).round(2)
    }

    forecast.merge!("start_date" => start_date, "end_date" => end_date)
  end

  private

  # Moyenne historique si pas de données sur la période
  def historical_average(scope, start_date, end_date)
    total     = scope.sum(:amount)
    min_date  = scope.minimum(:date)
    max_date  = scope.maximum(:date)
    months_count = [(max_date && min_date) ? ((max_date - min_date).to_i / 30.0).round : 1, 1].max
    (total / months_count * ((end_date - start_date).to_i / 30.0)).round(2)
  end
end
