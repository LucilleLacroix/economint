class ReconciliationsController < ApplicationController
  before_action :authenticate_user!

  def analyze
    uploaded_file = params[:bank_file]
    return redirect_to new_reconciliation_path, alert: "Veuillez sélectionner un fichier PDF" unless uploaded_file

    temp_path = Rails.root.join("tmp", uploaded_file.original_filename)
    File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

    # Extraire les transactions
    @transactions = PdfReaderService.extract_transactions(temp_path)

    File.delete(temp_path) if File.exist?(temp_path)
  end
end
