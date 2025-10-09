class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: [:edit, :update, :destroy, :add_money]

  def index
    @goals = current_user.goals
    @total_revenues = current_user.revenues.sum(:amount)
    @total_expenses = current_user.expenses.sum(:amount)
    @available_balance = current_user.revenues.sum(:amount) - current_user.expenses.sum(:amount) - current_user.goals.sum(:current_amount)
  end

  def new
    @goal = current_user.goals.new
  end

  def create
    @goal = current_user.goals.new(goal_params)
    if @goal.save
      redirect_to goals_path, notice: "Objectif créé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @goal.update(goal_params)
      redirect_to goals_path, notice: "Objectif mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: "Objectif supprimé."
  end

  # ✅ Action pour ajouter de l’argent à un objectif
  def add_money
    @goal = current_user.goals.find(params[:id])
    amount = params[:amount].to_f

    # Recalcul du solde disponible avant l'ajout
    total_revenues = current_user.revenues.sum(:amount)
    total_expenses = current_user.expenses.sum(:amount)
    total_saved = current_user.goals.sum(:current_amount)
    @available_balance = total_revenues - total_expenses - total_saved

    if amount.positive?
      if amount <= @available_balance
        # Ajout explicite au lieu de +=
        new_amount = @goal.current_amount.to_f + amount
        @goal.current_amount = new_amount

        if @goal.save
          flash.now[:notice] = "Épargne ajoutée avec succès !"
        else
          flash.now[:alert] = "Impossible d'ajouter l'argent à cet objectif."
        end
      else
        flash.now[:alert] = "Solde insuffisant pour ajouter ce montant."
      end
    else
      flash.now[:alert] = "Le montant doit être supérieur à 0."
    end


    # Recalcul du solde disponible après l’ajout pour l’affichage
    total_saved_after = current_user.goals.sum(:current_amount)
    @available_balance = current_user.revenues.sum(:amount) -
                     current_user.expenses.sum(:amount) -
                     current_user.goals.sum(:current_amount)


    # Recharger la liste des objectifs
    @goals = current_user.goals.order(deadline: :asc)

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
    params.require(:goal).permit(:title, :target_amount, :current_amount, :deadline)
  end
end
