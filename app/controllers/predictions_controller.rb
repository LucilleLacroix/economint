class PredictionsController < ApplicationController
  include PunditResources
  before_action :authenticate_user!
  before_action :set_prediction, only: [:show, :edit, :update, :destroy]

  # GET /predictions
  def index
    @predictions = policy_scope(Prediction)
  end

  # GET /predictions/:id
  def show
    authorize @prediction
  end

  # GET /predictions/new
  def new
    @prediction = current_user.predictions.new
    authorize @prediction
  end

  # POST /predictions
  def create
    @prediction = current_user.predictions.new(prediction_params)
    authorize @prediction

    # Calculer les prévisions
    base_start     = @prediction.base_start_date
    base_end       = @prediction.base_end_date
    forecast_start = @prediction.forecast_start_date
    forecast_end   = @prediction.forecast_end_date

    @prediction.forecast_data = {
      "base"     => @prediction.generate_forecast(base_start, base_end),
      "forecast" => @prediction.generate_forecast(forecast_start, forecast_end)
    }

    if @prediction.save
      redirect_to @prediction, notice: "Prédiction créée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /predictions/:id/edit
  def edit
    authorize @prediction
  end

  # PATCH/PUT /predictions/:id
  def update
    authorize @prediction

    if @prediction.update(prediction_params)
      # Recalculer les prévisions si dates modifiées
      @prediction.forecast_data = {
        "base"     => @prediction.generate_forecast(@prediction.base_start_date, @prediction.base_end_date),
        "forecast" => @prediction.generate_forecast(@prediction.forecast_start_date, @prediction.forecast_end_date)
      }
      @prediction.save
      redirect_to predictions_path, notice: "Prédiction mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /predictions/:id
  def destroy
    authorize @prediction
    @prediction.destroy
    redirect_to predictions_path, notice: "Prédiction supprimée."
  end

  private

  def set_prediction
    @prediction = current_user.predictions.find(params[:id])
  end

  def prediction_params
    params.require(:prediction).permit(
      :scenario_name,
      :base_start_date, :base_end_date,
      :forecast_start_date, :forecast_end_date
    )
  end
end
