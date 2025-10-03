class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    @categories = current_user.categories
  end

  def new
    @category = current_user.categories.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Catégorie créée !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: { success: true, category: @category }
    else
      render json: { success: false, errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    default_category = current_user.categories.find_or_create_by(name: "Default") do |c|
      c.color = "#E0E0E0"
    end

    # Déplacer les dépenses vers Default avant suppression
    @category.expenses.update_all(category_id: default_category.id)

    @category.destroy
    render json: { success: true, default_category_id: default_category.id }
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end
end
