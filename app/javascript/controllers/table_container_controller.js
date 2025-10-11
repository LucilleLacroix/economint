import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    ascending: Boolean
  }

  connect() {
    // Assure que le cursor indique que c'est cliquable
    this.element.querySelectorAll("th[data-sort]").forEach(th => {
      th.style.cursor = "pointer"
      th.addEventListener("click", () => this.sortColumn(th))
    })
    this.ascendingValue = true
  }

  sortColumn(header) {
    const table = this.element
    const index = Array.from(header.parentNode.children).indexOf(header)
    const type = header.dataset.sort
    const tbody = table.querySelector("tbody")
    const rows = Array.from(tbody.querySelectorAll("tr"))

    rows.sort((a, b) => {
      let aText = a.children[index].textContent.trim()
      let bText = b.children[index].textContent.trim()

      if (type === "number") {
        aText = parseFloat(aText.replace(/[^\d.-]/g,"")) || 0
        bText = parseFloat(bText.replace(/[^\d.-]/g,"")) || 0
      } else if (type === "date") {
        aText = new Date(aText)
        bText = new Date(bText)
      } else if (type === "string") {
        aText = aText.toLowerCase()
        bText = bText.toLowerCase()
      }

      return this.ascendingValue ? (aText > bText ? 1 : -1) : (aText < bText ? 1 : -1)
    })

    rows.forEach(row => tbody.appendChild(row))
    this.ascendingValue = !this.ascendingValue
  }
}
