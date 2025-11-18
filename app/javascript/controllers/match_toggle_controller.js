import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget

    // Ne rien faire si la ligne est validée
    if (button.disabled) return

    const txId = button.dataset.txId
    if (!txId) return

    const detailRow = document.getElementById(`match-details-${txId}`)
    if (!detailRow) return

    const isNowHidden = detailRow.classList.toggle("hidden")

    // Texte du bouton
    button.innerHTML = isNowHidden
      ? "👁️ Voir / Modifier"
      : "🔽 Masquer"
  }
}
