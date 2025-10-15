class BudgetsController < ApplicationController
  include PunditResources

  before_action :authenticate_user!
  before_action :set_budget, only: [:edit, :update, :destroy]

  # ✅ Liste tous les budgets de l'utilisateur
  def index
    @budgets = policy_scope(current_user.budgets.includes(:category).order(start_date: :desc))
    @budget = current_user.budgets.new
  end

  # ✅ Nouveau budget (peut venir d'une prévision)
  def new
    @budget = current_user.budgets.new(budget_params_from_forecast)
    authorize @budget
  end

  # ✅ Création
  def create
    @budget = current_user.budgets.new(budget_params)
    authorize @budget

    if @budget.save
      redirect_to budgets_path, notice: "Budget créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ✅ Édition
  def edit
    authorize @budget
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "budget_form",
          partial: "budgets/form",
          locals: { budget: @budget }
        )
      end
      format.html
    end
  end

  # ✅ Mise à jour
  def update
    authorize @budget
    if @budget.update(budget_params)
      redirect_to budgets_path, notice: "Budget mis à jour !"
    else
      render :edit, status: :unprocessable_entity
    end


  end

  # ✅ Suppression
  def destroy
    authorize @budget
    @budget.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("budget_#{@budget.id}")
      end
      format.html { redirect_to budgets_path, notice: "Budget supprimé !" }
    end

  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  end

  def budget_params
    params.require(:budget).permit(:category_id, :start_date, :end_date,
                                   :pessimistic_amount, :realistic_amount, :optimistic_amount)
  end

  def budget_params_from_forecast
    params.permit(:category_id, :start_date, :end_date,
                  :pessimistic_amount, :realistic_amount, :optimistic_amount)
  end
end
