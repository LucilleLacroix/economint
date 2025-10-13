class PredictionsController < ApplicationController
  include PunditResources

  before_action :authenticate_user!
  before_action :set_prediction, only: [:show, :edit, :update, :destroy]

  # ✅ Liste toutes les prédictions de l'utilisateur
  def index
    @predictions = policy_scope(current_user.predictions)
  end

  # ✅ Affiche une prédiction
  def show
    authorize @prediction
  end

  # ✅ Formulaire de création
  def new
    @prediction = current_user.predictions.new
    authorize @prediction
  end

  # ✅ Création d'une prédiction
  def create
    @prediction = current_user.predictions.new(prediction_params)
    authorize @prediction

    if @prediction.save
      redirect_to predictions_path, notice: "Prédiction créée avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ✅ Formulaire d'édition
  def edit
    authorize @prediction
  end

  # ✅ Mise à jour d'une prédiction
  def update
    authorize @prediction

    if @prediction.update(prediction_params)
      redirect_to predictions_path, notice: "Prédiction mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ✅ Suppression
  def destroy
    authorize @prediction
    @prediction.destroy
    redirect_to predictions_path, notice: "Prédiction supprimée."
  end

  private

  # 🔑 On ne récupère que les prédictions de l'utilisateur courant
  def set_prediction
    @prediction = current_user.predictions.find(params[:id])
  end

  # ✅ Strong params
  def prediction_params
    params.require(:prediction).permit(:scenario_name, :forecast_data)
  end
end
