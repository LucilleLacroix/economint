class CategoriesController < ApplicationController
  include PunditResources

  before_action :authenticate_user!
  before_action :set_category, only: [:update, :destroy, :edit]

  # ✅ Liste toutes les catégories de l'utilisateur pour un type donné
  def index
    @category_type = category_type_param
    @categories = policy_scope(current_user.categories.where(category_type: @category_type))
    @category = current_user.categories.new(category_type: @category_type)
  end

  # ✅ Création d'une catégorie
  def create
    @category_type = params[:category_type] || "expense"
    @category = current_user.categories.new(category_params.merge(category_type: @category_type))
    authorize @category

    if @category.save
      flash.now[:notice] = "Catégorie créée !"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "categories",
              partial: "categories/category_row",
              locals: { category: @category }
            ),
            turbo_stream.replace(
              "category_form",
              partial: "categories/form",
              locals: {
                category: current_user.categories.new(category_type: @category_type),
                category_type: @category_type
              }
            ),
            turbo_stream.replace(
              "flash",
              partial: "shared/flash"
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

  # ✅ Édition
  def edit
    authorize @category
    @category_type = @category.category_type

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "category_form",
          partial: "categories/form",
          locals: { category: @category, category_type: @category_type }
        )
      end
      format.html
    end
  end

  # ✅ Mise à jour
  def update
    authorize @category

    if @category.update(category_params)
      flash.now[:notice] = "Catégorie Mise à Jour !"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("category_#{@category.id}", partial: "categories/category_row", locals: { category: @category }),
            turbo_stream.replace("category_form", partial: "categories/form", locals: { category: current_user.categories.new(category_type: @category.category_type), category_type: @category.category_type }),
            turbo_stream.replace("flash", partial: "shared/flash")

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

  # ✅ Suppression
  def destroy
    authorize @category

    default_category = current_user.categories.find_or_create_by(
      name: "Default", category_type: @category.category_type
    ) { |c| c.color = "#E0E0E0" }

    @category.expenses.update_all(category_id: default_category.id) if @category.expenses.any?
    @category.revenues.update_all(category_id: default_category.id) if @category.revenues.any?

    @category.destroy

    respond_to do |format|
      # Turbo Stream pour mise à jour instantanée sans rechargement
      format.turbo_stream do
        flash.now[:notice] = "Catégorie supprimée ! les éléments associés ont été déplacés vers la catégorie 'Default'."
        render turbo_stream: [
          turbo_stream.remove("category_#{@category.id}"),       # Supprime la ligne du tableau
          turbo_stream.replace("flash", partial: "shared/flash")  # Met à jour le flash
        ]
      end
      format.html do
        redirect_to categories_path(category_type: @category.category_type), notice: message
      end
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
