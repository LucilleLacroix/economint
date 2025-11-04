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

    # Déterminer la période du relevé pour filtrer les dépenses/revenus
    dates = raw_transactions.map { |t| t[:date] }.compact
    start_date = dates.min
    end_date   = dates.max

    # Étape 2️⃣ : Analyser et matcher avec les dépenses/revenus
    matched_transactions = PdfTransactionMatcher.new(
      raw_transactions,
      current_user,
      start_date: start_date,
      end_date: end_date
    ).match_all

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
    authorize @reconciliation, :validate_match?

    # 1️⃣ Valider la transaction sélectionnée
    tx = @reconciliation.transactions.find(params[:tx_id])
    tx.update(match_validated: true)

    # 2️⃣ Construire la liste des entrées déjà validées
    exclude_entries = @reconciliation.transactions
                                      .where(match_validated: true)
                                      .map { |t| [t.matchable_type, t.matchable_id] }
                                      .compact

    # 3️⃣ Recalculer les scores des autres transactions non validées
    remaining_transactions = @reconciliation.transactions.where(match_validated: false)
    matcher = PdfTransactionMatcher.new(
      remaining_transactions.map { |t|
        {
          id: t.id,
          date: t.date,
          description: t.description,
          amount: t.amount,
          type: t.amount < 0 ? 'expense' : 'revenue'
        }
      },
      current_user,
      start_date: @reconciliation.transactions.minimum(:date),
      end_date: @reconciliation.transactions.maximum(:date),
      exclude_entries: exclude_entries
    )

    new_matches = matcher.match_all

    # 4️⃣ Mettre à jour les transactions restantes avec leurs nouveaux scores et correspondances
    new_matches.each do |m|
      tx_to_update = @reconciliation.transactions.find(m[:id])
      tx_to_update.update(
        matchable_id: m[:matchable_id],
        matchable_type: m[:matchable_type],
        match_score: m[:match_score]
      )
    end

    # 5️⃣ Répondre via Turbo pour mettre à jour le tableau
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("tx_#{tx.id}_status", partial: "reconciliations/validated_badge", locals: { tx: tx }),
          turbo_stream.replace(
              "reconciliation_transactions",
              partial: "reconciliations/transactions_table",
              locals: { reconciliation: @reconciliation }
            )

      ]
      end
      format.html { redirect_to @reconciliation, notice: "Match validé et recalculé ✅" }
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
