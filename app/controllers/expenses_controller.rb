class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[edit update destroy]

  def index
    start_date = params[:start_date].presence || 1.month.ago.to_date
    end_date   = params[:end_date].presence || Date.today

    @expenses = current_user.expenses.includes(:category)
                        .where(date: start_date..end_date)

    # Hash { "Food" => 120.0, "Transport" => 50.0, ... }
    @expenses_by_category = @expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount]
    end.to_h

    @total_expenses = @expenses.sum(:amount)
    @categories = current_user.categories
  end

  def new
    @expense = current_user.expenses.new(date: Date.today)
    @categories = current_user.categories
  end

  def create
    @expense = current_user.expenses.new(expense_params)
    if @expense.save
      redirect_to expenses_path, notice: "Dépense créée avec succès !"
    else
      @categories = current_user.categories
      render :new
    end
  end

  def edit
    @categories = current_user.categories
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Dépense mise à jour !"
    else
      @categories = current_user.categories
      render :edit
    end
  end

  def destroy
    @expense = current_user.expenses.find(params[:id])
    if @expense.destroy
      # Recalculer les données pour le chart
      expenses = current_user.expenses.includes(:category)
      expenses_by_category = expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
        category = current_user.categories.find_by(id: cat_id)
        [category&.name || "Default", amount]
      end.to_h
      render json: { success: true, expenses_by_category: expenses_by_category, expenses: expenses.as_json(include: :category) }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end


  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:category_id, :amount, :description, :date)
  end
end
