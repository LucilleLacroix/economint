class PagesController < ApplicationController
  def home
    return unless user_signed_in?

    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date   = params[:end_date]&.to_date || Date.today.end_of_month

    # Dépenses
    @expenses = current_user.expenses.includes(:category).where(date: @start_date..@end_date)
    @total_expenses = @expenses.sum(:amount)
    @expenses_by_category = @expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Sans catégorie", amount]
    end.to_h.transform_keys(&:to_s)

    # Revenus
    @revenues = current_user.revenues.includes(:category).where(date: @start_date..@end_date)
    @total_revenues = @revenues.sum(:amount)
    @revenues_by_category = @revenues.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Autre", amount]
    end.to_h.transform_keys(&:to_s)
  end
end
