class ReconciliationsController < ApplicationController
   before_action :authenticate_user!
  def new
    authorize Reconciliation
  end

  def analyze
    authorize Reconciliation
    uploaded_file = params[:bank_file]
    if uploaded_file.nil?
      redirect_to new_reconciliation_path, alert: "Aucun fichier sélectionné."
      return
    end
    unless uploaded_file.content_type == "application/pdf"
      redirect_to new_reconciliation_path, alert: "Le fichier doit être un PDF."
      return
    end
    # 1. Sauvegarde temporaire du fichier
    temp_path = Rails.root.join("tmp", uploaded_file.original_filename)
    File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }
    # 2️. Extraction du texte selon le type de fichier
    extracted_text = extracted_text = PdfReaderService.extract(temp_path)
    # 3️. Suppression du fichier temporaire
    File.delete(temp_path) if File.exist?(temp_path)
    # 4️. Séparation du texte en lignes pour affichage
    @lines = extracted_text.split("\n").reject(&:blank?)
  end
  
end
