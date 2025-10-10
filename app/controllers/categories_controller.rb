class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:update, :destroy]

  def index
    @category_type = category_type_param
    @categories = current_user.categories.where(category_type: @category_type)
    @category = current_user.categories.new(category_type: @category_type)
  end

  # POST /categories
  def create
    @category_type = params[:category_type] || "expense"
    @category = current_user.categories.new(category_params.merge(category_type: @category_type))

    if @category.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # 👇 Ajoute la nouvelle ligne à la fin du <tbody id="categories">
            turbo_stream.append(
              "categories",
              partial: "categories/category_row",
              locals: { category: @category }
            ),

            # 👇 Remplace le formulaire par un nouveau vide
            turbo_stream.replace(
              "category_form",
              partial: "categories/form",
              locals: {
                category: current_user.categories.new(category_type: @category_type),
                category_type: @category_type
              }
            )
          ]
        end

        format.html do
          redirect_to categories_path(category_type: @category_type),
                      notice: "Catégorie créée !"
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "category_form",
            partial: "categories/form",
            locals: { category: @category, category_type: @category_type }
          )
        end

        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end




  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("category_#{@category.id}", partial: "categories/category_row", locals: { category: @category }),
            turbo_stream.replace("category_form", partial: "categories/form", locals: { category: current_user.categories.new(category_type: @category.category_type), category_type: @category.category_type })
          ]
        end
        format.html { redirect_to categories_path(category_type: @category.category_type), notice: "Catégorie mise à jour !" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("category_form", partial: "categories/form", locals: { category: @category, category_type: @category.category_type }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end



  # GET /categories/:id/edit
  def edit
    @category = current_user.categories.find(params[:id])
    @category_type = @category.category_type

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("category_form", partial: "categories/form", locals: { category: @category, category_type: @category_type }) }
      format.html # fallback classique si Turbo non utilisé
    end
  end

  def destroy
    default_category = current_user.categories.find_or_create_by(
      name: "Default", category_type: @category.category_type
    ) { |c| c.color = "#E0E0E0" }

    @category.expenses.update_all(category_id: default_category.id) if @category.expenses.any?
    @category.revenues.update_all(category_id: default_category.id) if @category.revenues.any?

    @category.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to categories_path(category_type: @category.category_type), notice: "Catégorie supprimée !" }
    end
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
