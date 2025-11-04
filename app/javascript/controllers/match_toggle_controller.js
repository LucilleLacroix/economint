// app/javascript/controllers/match_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"]

  connect() {
    // utile pour debug : vérifier qu'il est bien connecté dans la console du navigateur
    // console.log("match-toggle connected", this.element)
  }

  toggle(event) {
    const button = event.currentTarget
    const txId = button.dataset.txId
    if (!txId) return

    const detailRow = document.getElementById(`match-details-${txId}`)
    if (!detailRow) {
      console.warn(`No detail row found for txId=${txId}`)
      return
    }

    const isNowHidden = detailRow.classList.toggle("hidden")

    // Mettre le texte du bouton de façon sûre (préserver emoji)
    button.textContent = isNowHidden ? "👀 Voir correspondance" : "⬆️ Masquer"
  }
}
