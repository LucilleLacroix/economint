class GoalsController < ApplicationController
  include PunditResources
  before_action :authenticate_user!
  before_action :set_goal, only: [:edit, :update, :destroy, :add_money]

  # ✅ Liste les objectifs + calcul des soldes
  def index
    @goals = policy_scope(current_user.goals.order(deadline: :asc))

    total_revenues = current_user.revenues.sum(:amount)
    total_expenses = current_user.expenses.sum(:amount)
    total_saved = current_user.goals.sum(:current_amount)

    @available_balance = total_revenues - total_expenses - total_saved
  end

  # ✅ Nouveau
  def new
    @goal = current_user.goals.new
    authorize @goal
  end

  # ✅ Création
  def create
    @goal = current_user.goals.new(goal_params)
    authorize @goal

    if @goal.save
      redirect_to goals_path, notice: "Objectif créé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end



  # ✅ Édition
  def edit
    authorize @goal
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("goal_form", partial: "goals/form", locals: { goal: @goal })
      end
      format.html
    end
  end

  # ✅ Mise à jour
  def update
    authorize @goal
    if @goal.update(goal_params)
      redirect_to goals_path, notice: "Objectif mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ✅ Suppression
  def destroy
    authorize @goal
    @goal.destroy

    # Recalcul du solde après suppression
    total_revenues = current_user.revenues.sum(:amount)
    total_expenses = current_user.expenses.sum(:amount)
    total_saved = current_user.goals.sum(:current_amount)
    @available_balance = total_revenues - total_expenses - total_saved

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("goal_#{@goal.id}"), # supprime la ligne
          turbo_stream.replace("available_balance", partial: "goals/available_balance", locals: { available_balance: @available_balance }),
          turbo_stream.prepend("flash_messages", partial: "shared/flash", locals: { notice: "Objectif supprimé !" })
        ]
      end
      format.html { redirect_to goals_path, notice: "Objectif supprimé !" }
    end
  end




  # ✅ Ajout d’argent à un objectif
 def add_money
  authorize @goal
  amount = params[:amount].to_f

  total_revenues = current_user.revenues.sum(:amount)
  total_expenses = current_user.expenses.sum(:amount)
  total_saved = current_user.goals.sum(:current_amount)
  @available_balance = total_revenues - total_expenses - total_saved

  if amount.positive? && amount <= @available_balance
    @goal.update(current_amount: @goal.current_amount.to_f + amount)
    flash.now[:notice] = "Épargne ajoutée avec succès !"
  elsif !amount.positive?
    flash.now[:alert] = "Le montant doit être supérieur à 0."
  else
    flash.now[:alert] = "Solde insuffisant pour ajouter ce montant."
  end

  # Recharge les données après mise à jour
  @goals = policy_scope(current_user.goals.order(deadline: :asc))
  total_saved_after = current_user.goals.sum(:current_amount)
  @available_balance = total_revenues - total_expenses - total_saved_after

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.replace("goals_table", partial: "goals/goals_table", locals: { goals: @goals }),
        turbo_stream.replace("available_balance", partial: "goals/available_balance", locals: { available_balance: @available_balance }),
        turbo_stream.prepend("flash_messages", partial: "shared/flash")
      ]
    end
    format.html { redirect_to goals_path }
  end
end


  private

  def set_goal
    @goal = current_user.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:title, :target_amount, :current_amount, :deadline, :goal_type, :category_id)
  end
end
