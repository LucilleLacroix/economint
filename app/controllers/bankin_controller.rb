class BankinController < ApplicationController
  before_action :authenticate_user!

  # Redirige vers la page OAuth de la banque
  def connect
    bank = params[:bank]
    redirect_uri = bankin_callback_url

    # URL OAuth générée dynamiquement selon la banque choisie
    oauth_url = "https://app.bankin.com/oauth/authorize?client_id=#{ENV['BANKIN_CLIENT_ID']}&redirect_uri=#{redirect_uri}&response_type=code&scope=transactions"

    redirect_to oauth_url
  end

  # Callback après consentement
  def callback
    code = params[:code]
    if code.blank?
      redirect_to new_reconciliation_path, alert: "Connexion bancaire annulée"
      return
    end

    # Échange du code contre un token temporaire
    response = HTTParty.post(
      "https://sync.bankin.com/v2/oauth/token",
      body: {
        grant_type: "authorization_code",
        client_id: ENV['BANKIN_CLIENT_ID'],
        client_secret: ENV['BANKIN_CLIENT_SECRET'],
        code: code,
        redirect_uri: bankin_callback_url
      }
    )

    token_data = JSON.parse(response.body)
    session[:bank_token] = token_data["access_token"]

    redirect_to new_reconciliation_path, notice: "Connexion réussie ! Vous pouvez maintenant analyser vos transactions."
  end
end
