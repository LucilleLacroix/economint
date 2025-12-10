class ReconciliationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reconciliation, only: [:show, :destroy, :validate_match]
  after_action :verify_authorized, except: [:index]

  def index
    @reconciliations = policy_scope(Reconciliation)
  end

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

    # Extraction du texte du PDF
    text = PdfReaderService.extract_text(temp_path)

    # Détection automatique de la banque
    bank = PdfReaderService.detect_bank(text)
    Rails.logger.info("Banque détectée : #{bank}")

    parser =
      case bank
      when :credit_mutuel   then CreditMutuelParser
      when :credit_agricole then CreditAgricoleParser
      when :banque_postale  then BanquePostaleParser
      else
        DefaultParser
      end

    raw_transactions = parser.parse(text)
    File.delete(temp_path) if File.exist?(temp_path)

    dates      = raw_transactions.map { |t| t[:date] }.compact
    start_date = dates.min
    end_date   = dates.max

    matched_transactions = PdfTransactionMatcher.new(
      raw_transactions,
      current_user,
      start_date: start_date,
      end_date: end_date
    ).match_all

    if @reconciliation.save
      matched_transactions.each do |tx|
        @reconciliation.transactions.create(
          date:        tx[:date],
          description: tx[:description],
          amount:      tx[:amount],
          matchable:   tx[:matchable],
          match_score: tx[:match_score]
        )
      end

      redirect_to @reconciliation, notice: "Relevé analysé et rapproché avec succès ✅"
    else
      render :new
    end
  end

  def show
    authorize @reconciliation
    @transactions = @reconciliation.transactions.includes(:matchable)
  end

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
          id:          t.id,
          date:        t.date,
          description: t.description,
          amount:      t.amount
        }
      },
      current_user,
      start_date:      @reconciliation.transactions.minimum(:date),
      end_date:        @reconciliation.transactions.maximum(:date),
      exclude_entries: exclude_entries
    )

    new_matches = matcher.match_all

    new_matches.each do |m|
      tx_to_update = @reconciliation.transactions.find(m[:id])
      tx_to_update.update(
        matchable_id:   m[:matchable_id],
        matchable_type: m[:matchable_type],
        match_score:    m[:match_score]
      )
    end

    # 👉 plus de turbo_stream ici, on fait simple :
    redirect_to @reconciliation, notice: "Match validé et recalculé ✅"
  end



  def destroy
    authorize @reconciliation
    @reconciliation.destroy
    redirect_to reconciliations_path, notice: "Relevé supprimé"
  end

  private

  def reconciliation_params
    # 👉 on ne met PAS :bank_file ici, car ce n'est pas une colonne du modèle
    params.require(:reconciliation).permit(:name)
  end

  def set_reconciliation
    @reconciliation = Reconciliation.find(params[:id])
  end
end
