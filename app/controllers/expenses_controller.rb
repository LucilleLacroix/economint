class ExpensesController < ApplicationController
  include PunditResources
  before_action :authenticate_user!
  before_action :set_expense, only: %i[edit update destroy]
  

  def index
    start_date = params[:start_date].presence || 1.month.ago.to_date
    end_date   = params[:end_date].presence || Date.today

    @expenses = policy_scope(current_user.expenses.includes(:category)
                            .where(date: start_date..end_date))

    @expenses_by_category = @expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount]
    end.to_h

    @total_expenses = @expenses.sum(:amount)
    @category_type = "expense"                     # Indique le type pour le form partagé
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def new
    @expense = current_user.expenses.new(date: Date.today)
    authorize @expense
    @category_type = "expense"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def edit
    authorize @expense
    @category_type = "expense"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def create
    @expense = current_user.expenses.new(expense_params)
    authorize @expense
    if @expense.save
      redirect_to expenses_path, notice: "Dépense créée avec succès !"
    else
      @category_type = "expense"
      @categories = current_user.categories.where(category_type: @category_type)
      render :new
    end
  end

  def update
    authorize @expense
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Dépense mise à jour !"
    else
      @category_type = "expense"
      @categories = current_user.categories.where(category_type: @category_type)
      render :edit
    end
  end

  def destroy
    authorize @expense
    @expense.destroy
    expenses = current_user.expenses.includes(:category)
    expenses_by_category = expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount]
    end.to_h
    render json: { success: true, expenses_by_category: expenses_by_category, expenses: expenses.as_json(include: :category) }
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:category_id, :amount, :description, :date)
  end
end
