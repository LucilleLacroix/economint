// app/javascript/controllers/transactions_chart_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    resource: String,       // "expenses" ou "revenues"
    chartId: String,        // ID du canvas
    categories: Array,      // JSON des catégories
    dataByCategory: Object  // ✅ Ajouté ici
  }

  connect() {
    this.canvas = document.getElementById(this.chartIdValue)
    if (!this.canvas) return

    this.renderChart(this.dataByCategoryValue) // ✅ plus besoin de JSON.parse
    this.attachDeleteEvents()
  }

  renderChart(dataObj) {
    const ctx = this.canvas.getContext("2d")
    const labels = Object.keys(dataObj)
    const data = Object.values(dataObj)
    const colors = labels.map(label => {
      const cat = this.categoriesValue.find(c => c.name === label)
      return cat ? cat.color : "#E0E0E0"
    })

    if (window[this.chartIdValue] instanceof Chart) {
      window[this.chartIdValue].destroy()
    }

    window[this.chartIdValue] = new Chart(ctx, {
      type: "pie",
      data: {
        labels,
        datasets: [{
          data,
          backgroundColor: colors,
          borderColor: "#fff",
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              usePointStyle: true,      // ✅ rend le point en cercle
              pointStyle: "circle",
              color: "white",         // ✅ couleur du texte (tu peux mettre n'importe quelle couleur)
              font: { size: 16, weight: "500" },
              padding: 20               // ✅ augmente l’espace entre les items de la légende
            },
           },
          tooltip: {
            callbacks: {
              label(context) {
                const value = context.raw
                const total = data.reduce((a, b) => a + b, 0)
                const percent = ((value / total) * 100).toFixed(1)
                return `  ${value}`
              }
            }
          }
        },
        animation: { animateRotate: true, animateScale: true, duration: 1200 }
      }
    })
  }

  attachDeleteEvents() {
    const singularMap = { expenses: "expense", revenues: "revenue" }
    const singularResource = singularMap[this.resourceValue] || this.resourceValue

    document.querySelectorAll(`.delete-${singularResource}`).forEach(btn => {
      btn.addEventListener("click", (event) => {
        if (!confirm("Voulez-vous vraiment supprimer ?")) return

        const id = event.currentTarget.dataset.id
        fetch(`/${this.resourceValue}/${id}`, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            "Accept": "application/json"
          }
        })
        .then(res => res.json())
        .then(data => {
          if (data.success) window.location.reload()
          else alert("Erreur lors de la suppression !")
        })
      })
    })
  }
}
