class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:update, :destroy]

  # GET /categories
  def index
    @category_type = category_type_param
    @categories = current_user.categories.where(category_type: @category_type)
  end

  # GET /categories/new
  def new
    @category_type = category_type_param
    @category = current_user.categories.new(category_type: @category_type)
  end

  # POST /categories
  def create
    @category_type = category_type_param
    @category = current_user.categories.new(category_params.merge(category_type: @category_type))

    if @category.save
      redirect_to categories_path(category_type: @category_type), notice: "Catégorie créée !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      render json: { success: true, category: @category }
    else
      render json: { success: false, errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /categories/:id
  def destroy
    default_category = current_user.categories.find_or_create_by(
      name: "Default", category_type: @category.category_type
    ) { |c| c.color = "#E0E0E0" }

    @category.expenses.update_all(category_id: default_category.id) if @category.expenses.any?
    @category.revenues.update_all(category_id: default_category.id) if @category.revenues.any?

    @category.destroy
    render json: { success: true, default_category_id: default_category.id }
  end

  private

  def category_type_param
    params[:category_type].presence || "expense"
  end

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end
end

