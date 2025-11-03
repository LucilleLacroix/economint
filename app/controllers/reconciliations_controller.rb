class ReconciliationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reconciliation, only: [:show, :destroy, :validate_match]
  after_action :verify_authorized, except: [:index]

  # GET /reconciliations
  def index
    @reconciliations = policy_scope(Reconciliation)
  end

  # GET /reconciliations/new
  def new
    @reconciliation = Reconciliation.new
    authorize @reconciliation
  end

  # POST /reconciliations
  def create
    @reconciliation = current_user.reconciliations.new(reconciliation_params)
    authorize @reconciliation

    uploaded_file = params[:reconciliation][:bank_file]
    unless uploaded_file
      return redirect_to new_reconciliation_path, alert: "Veuillez sélectionner un fichier PDF"
    end

    temp_path = Rails.root.join("tmp", uploaded_file.original_filename)
    File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

    # Étape 1️⃣ : Extraire les transactions depuis le PDF
    raw_transactions = PdfReaderService.extract_transactions(temp_path)
    File.delete(temp_path) if File.exist?(temp_path)

    # Étape 2️⃣ : Analyser et matcher avec les dépenses/revenus
    matched_transactions = PdfTransactionMatcher.new(raw_transactions, current_user).match_all

    if @reconciliation.save
      # Étape 3️⃣ : Sauvegarder les transactions appariées
      matched_transactions.each do |tx|
        @reconciliation.transactions.create(
          date: tx[:date],
          description: tx[:description],
          amount: tx[:amount],
          matchable: tx[:matchable],
          match_score: tx[:match_score]
        )
      end

      redirect_to @reconciliation, notice: "Relevé analysé, rapproché et sauvegardé avec succès ✅"
    else
      render :new
    end
  end

  # GET /reconciliations/:id
  def show
    authorize @reconciliation
    @transactions = @reconciliation.transactions.includes(:matchable)
  end

  # PATCH /reconciliations/:id/validate_match
  def validate_match
    authorize @reconciliation
    tx = @reconciliation.transactions.find(params[:tx_id])
    tx.update(match_validated: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "tx_#{tx.id}_status",
          partial: "reconciliations/validated_badge",
          locals: { tx: tx }
        )
      end
      format.html { redirect_to reconciliation_path(@reconciliation), notice: "Match validé ✅" }
    end
  end



  # DELETE /reconciliations/:id
  def destroy
    authorize @reconciliation
    @reconciliation.destroy
    redirect_to reconciliations_path, notice: "Relevé supprimé"
  end

  private

  def reconciliation_params
    params.require(:reconciliation).permit(:name)
  end

  def set_reconciliation
    @reconciliation = Reconciliation.find(params[:id])
  end
end
