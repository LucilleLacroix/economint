class ExpensesController < ApplicationController
  include PunditResources
  before_action :authenticate_user!
  before_action :set_expense, only: %i[edit update destroy]

  def index
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date   = params[:end_date]&.to_date || Date.today.end_of_month

    @expenses = policy_scope(
      current_user.expenses
                  .includes(:category)
                  .where(date: @start_date..@end_date)
    )

    @expenses_by_category = @expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount]
    end.to_h

    @total_expenses = @expenses.sum(:amount)
    @category_type = "expense"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def new
    @expense = current_user.expenses.new(
      amount: params[:amount],
      date: params[:date] || Date.today,
      description: params[:description]
    )
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
      # Si création depuis le tableau de rapprochement, rediriger vers le relevé
      if params[:reconciliation_id].present?
        redirect_to reconciliation_path(params[:reconciliation_id]), notice: "Dépense créée avec succès !"
      else
        redirect_to expenses_path, notice: "Dépense créée avec succès !"
      end
    else
      @category_type = "expense"
      @categories = current_user.categories.where(category_type: @category_type)
      render :new
    end
  end

  def update
    authorize @expense
    if @expense.update(expense_params)
      if params[:reconciliation_id].present?
        redirect_to reconciliation_path(params[:reconciliation_id]), notice: "Dépense mise à jour !"
      else
        redirect_to expenses_path, notice: "Dépense mise à jour !"
      end
    else
      @category_type = "expense"
      @categories = current_user.categories.where(category_type: @category_type)
      render :edit
    end
  end

  def destroy
    authorize @expense
    @expense.destroy

    expenses = policy_scope(current_user.expenses.includes(:category))
    data_by_category = expenses.group(:category_id).sum(:amount).map do |cat_id, amount|
      next if amount <= 0
      category = current_user.categories.find_by(id: cat_id)
      [category.name, amount] if category
    end.compact.to_h

    respond_to do |format|
      format.json { render json: { success: true, data_by_category: data_by_category } }
      format.html { redirect_to expenses_path, notice: "Dépense supprimée !" }
      format.turbo_stream do
        flash.now[:notice] = "Dépense supprimée !"
        render turbo_stream: [
          turbo_stream.remove("expense_#{@expense.id}"),
          turbo_stream.replace("flash", partial: "shared/flash")
        ]
      end
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
