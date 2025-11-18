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

    # Sauvegarde temporaire du PDF
    temp_path = Rails.root.join("tmp", uploaded_file.original_filename)
    File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

    # 1️⃣ Extraction du texte du PDF
    text = PdfReaderService.extract_text(temp_path)

    # 2️⃣ Détection automatique de la banque
    bank = PdfReaderService.detect_bank(text)
    Rails.logger.info("Banque détectée : #{bank}")

    # 3️⃣ Sélection du parser
    parser =
      case bank
      when :credit_mutuel   then CreditMutuelParser

      when :credit_agricole then CreditAgricoleParser
      when :banque_postale  then BanquePostaleParser
      else
        DefaultParser
      end

    # 4️⃣ Parsing des transactions selon banque
    raw_transactions = parser.parse(text)

    File.delete(temp_path) if File.exist?(temp_path)

    # 5️⃣ Extraction période
    dates = raw_transactions.map { |t| t[:date] }.compact
    start_date = dates.min
    end_date   = dates.max

    # 6️⃣ Matching intelligent
    matched_transactions = PdfTransactionMatcher.new(
      raw_transactions,
      current_user,
      start_date: start_date,
      end_date: end_date
    ).match_all

    # 7️⃣ Sauvegarde
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

      redirect_to @reconciliation, notice: "Relevé analysé et rapproché avec succès ✅"
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
    # ❗❗ Correction : NE PAS inclure :bank_file
    params.require(:reconciliation).permit(:name)
  end

  def set_reconciliation
    @reconciliation = Reconciliation.find(params[:id])
  end
end
