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
      return redirect_to new_reconciliation_path, alert: "Veuillez fournir un fichier bancaire à analyser"
    end

    # --- Étape 1 : lire le CSV et créer les transactions brutes ---
    raw_transactions = []
    CSV.foreach(uploaded_file.path, headers: true) do |row|
      begin
        raw_transactions << {
          date: Date.parse(row['date']),
          description: row['description'],
          amount: row['amount'].to_f
        }
      rescue ArgumentError
        next # Ignorer les lignes mal formées
      end
    end

    if raw_transactions.empty?
      return redirect_to new_reconciliation_path, alert: "Aucune transaction valide trouvée dans le fichier"
    end

    # --- Étape 2 : déterminer la période du relevé ---
    start_date = params[:reconciliation][:start_date].presence || raw_transactions.map { |t| t[:date] }.min
    end_date   = params[:reconciliation][:end_date].presence   || raw_transactions.map { |t| t[:date] }.max

    # --- Étape 3 : rapprocher les transactions ---
    matched_transactions = PdfTransactionMatcher.new(
      raw_transactions,
      current_user,
      start_date: start_date,
      end_date: end_date
    ).match_all

    # --- Étape 4 : sauvegarder la réconciliation et les transactions ---
    if @reconciliation.save
      matched_transactions.each do |tx|
        @reconciliation.transactions.create(
          date: tx[:date],
          description: tx[:description],
          amount: tx[:amount],
          matchable: tx[:matchable],
          match_score: tx[:match_score]
        )
      end
      redirect_to @reconciliation, notice: "Transactions importées et rapprochées avec succès ✅"
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

    tx = @reconciliation.transactions.find(params[:tx_id])
    tx.update(match_validated: true)

    # Recalculer les nouveaux rapprochements en excluant les validés
    exclude_entries = @reconciliation.transactions
                                      .where(match_validated: true)
                                      .map { |t| [t.matchable_type, t.matchable_id] }
                                      .compact

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

    new_matches.each do |m|
      tx_to_update = @reconciliation.transactions.find(m[:id])
      tx_to_update.update(
        matchable_id: m[:matchable_id],
        matchable_type: m[:matchable_type],
        match_score: m[:match_score]
      )
    end

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
    params.require(:reconciliation).permit(:name, :bank_file, :start_date, :end_date)
  end

  def set_reconciliation
    @reconciliation = Reconciliation.find(params[:id])
  end
end
