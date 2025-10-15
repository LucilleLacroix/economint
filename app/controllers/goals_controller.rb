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
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Objectif créé avec succès !"
          render turbo_stream: [
            turbo_stream.append("goals", partial: "goals/goal_row", locals: { goal: @goal }),
            turbo_stream.replace("goal_form", partial: "goals/form", locals: { goal: current_user.goals.new })
          ]
        end
        format.html { redirect_to goals_path, notice: "Objectif créé avec succès !" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("goal_form", partial: "goals/form", locals: { goal: @goal })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
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
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Objectif mis à jour."
          render turbo_stream: [
            turbo_stream.replace("goal_#{@goal.id}", partial: "goals/goal_row", locals: { goal: @goal }),
            turbo_stream.replace("goal_form", partial: "goals/form", locals: { goal: current_user.goals.new })
          ]
        end
        format.html { redirect_to goals_path, notice: "Objectif mis à jour." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("goal_form", partial: "goals/form", locals: { goal: @goal })
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # ✅ Suppression
  def destroy
    authorize @goal
    @goal.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to goals_path, notice: "Objectif supprimé." }
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

    # Recharge des données après mise à jour
    @goals = policy_scope(current_user.goals.order(deadline: :asc))
    total_saved_after = current_user.goals.sum(:current_amount)
    @available_balance = total_revenues - total_expenses - total_saved_after

    respond_to do |format|
      format.turbo_stream
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
