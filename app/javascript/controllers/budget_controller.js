import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    opti: Number,   // limite de la barre optimiste
    real: Number,   // limite de la barre réaliste
    pess: Number,   // limite de la barre pessimiste
    spent: Number   // dépenses totales
  }

  static targets = ["optiBar", "realBar", "pessBar"]

  connect() {
    this.updateBars()
  }

  updateBars() {
    let spent = this.spentValue

    // --- Barre optimiste ---
    const optiFill = Math.min(spent, this.optiValue)

    // --- Barre réaliste ---
    const realFill = Math.min(Math.max(spent - this.optiValue, 0), this.realValue - this.optiValue)

    // --- Barre pessimiste ---
    const pessFill = Math.min(Math.max(spent - this.realValue, 0), this.pessValue - this.realValue)

    // Mise à jour des barres (% par rapport à leur propre limite)
    if (this.hasOptiBarTarget) this.optiBarTarget.style.width = (optiFill / this.optiValue * 100) + "%"
    if (this.hasRealBarTarget) this.realBarTarget.style.width = (realFill / (this.realValue - this.optiValue) * 100) + "%"
    if (this.hasPessBarTarget) this.pessBarTarget.style.width = (pessFill / (this.pessValue - this.realValue) * 100) + "%"
  }
}
