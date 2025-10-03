class RevenuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_revenue, only: %i[show edit update destroy]

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago.to_date
    end_date   = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    @revenues = current_user.revenues.includes(:category)
                           .where(date: start_date..end_date)

    @revenues_by_category = @revenues.group_by { |r| r.category&.name || "Default" }
                                     .transform_values { |arr| arr.sum(&:amount) }

    @category_type = "revenue"                       # Pour le form partagé
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def show; end

  def new
    @revenue = current_user.revenues.new
    @category_type = "revenue"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def edit
    @category_type = "revenue"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def create
    @revenue = current_user.revenues.new(revenue_params)
    if @revenue.save
      redirect_to revenues_path, notice: "Revenu créé avec succès."
    else
      @category_type = "revenue"
      @categories = current_user.categories.where(category_type: @category_type)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @revenue.update(revenue_params)
      redirect_to revenues_path, notice: "Revenu mis à jour."
    else
      @category_type = "revenue"
      @categories = current_user.categories.where(category_type: @category_type)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @revenue.destroy
    redirect_to revenues_path, notice: "Revenu supprimé."
  end

  private

  def set_revenue
    @revenue = current_user.revenues.find(params[:id])
  end

  def revenue_params
    params.require(:revenue).permit(:amount, :description, :date, :category_id)
  end
end
