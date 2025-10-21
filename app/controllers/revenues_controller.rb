class RevenuesController < ApplicationController
  include PunditResources
  before_action :authenticate_user!
  before_action :set_revenue, only: %i[edit update destroy]

  def index
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date   = params[:end_date]&.to_date || Date.today.end_of_month

    @revenues = policy_scope(
      current_user.revenues
                  .includes(:category)
                  .where(date: @start_date..@end_date)
    )

    @revenues_by_category = @revenues.group(:category_id).sum(:amount).map do |cat_id, amount|
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount]
    end.to_h

    @total_expenses = @revenues.sum(:amount)
    @category_type = "revenue"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def new
    @revenue = current_user.revenues.new
    authorize @revenue
    @category_type = "revenue"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def edit
    authorize @revenue
    @category_type = "revenue"
    @categories = current_user.categories.where(category_type: @category_type)
  end

  def create
    @revenue = current_user.revenues.new(revenue_params)
    authorize @revenue
    if @revenue.save
      redirect_to revenues_path, notice: "Revenu créé avec succès."
    else
      @category_type = "revenue"
      @categories = current_user.categories.where(category_type: @category_type)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @revenue
    if @revenue.update(revenue_params)
      redirect_to revenues_path, notice: "Revenu mis à jour."
    else
      @category_type = "revenue"
      @categories = current_user.categories.where(category_type: @category_type)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @revenue
    @revenue.destroy
    revenues = policy_scope(current_user.revenues.includes(:category))
    data_by_category =revenues.group(:category_id).sum(:amount).map do |cat_id, amount|
      next if amount <= 0
      category = current_user.categories.find_by(id: cat_id)
      [category&.name || "Default", amount ]  if category
    end.compact.to_h

    respond_to do |format|
      format.json {render json: {success: true, data_by_category: data_by_category }}
      format.html {redirect_to revenues_path, notice: "Revenu supprimé." }
      format.turbo_stream do
        flash.now[:notice] = "Revenu supprimé !"
        render turbo_stream: [
          turbo_stream.remove("revenue_#{@revenue.id}"),
          turbo_stream.replace("flash", partial: "shared/flash")
        ]
      end
    end
  end

  private

  def set_revenue
    @revenue = current_user.revenues.find(params[:id])
  end

  def revenue_params
    params.require(:revenue).permit(:amount, :description, :date, :category_id)
  end
end
