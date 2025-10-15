import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="category"
export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    // Si aucune catégorie sélectionnée au chargement, cocher tout par défaut
    if (this.hasCheckboxTarget && !this.checkboxTargets.some(cb => cb.checked)) {
      this.checkboxTargets.forEach(cb => cb.checked = true)
    }
  }

  selectAll() {
    this.checkboxTargets.forEach(cb => cb.checked = true)
  }

  deselectAll() {
    this.checkboxTargets.forEach(cb => cb.checked = false)
  }
}
