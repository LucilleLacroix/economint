// app/javascript/controllers/transactions_chart_controller.js
import { Controller } from "@hotwired/stimulus"

// Si tu veux utiliser Chart.js via importmap, tu dois ajouter le bundle global dans application.js
// et ne pas utiliser import "chart.js/auto" ici.
// On suppose que Chart est disponible globalement via <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

export default class extends Controller {
  static values = {
    resource: String,    // "expenses" ou "revenues"
    chartId: String,     // ID du canvas
    categories: Array    // tableau JSON des catégories
  }

  connect() {
    this.canvas = document.getElementById(this.chartIdValue)
    if (!this.canvas) return

    const dataByCategory = JSON.parse(this.data.get("dataByCategory") || "{}")

    this.renderChart(dataByCategory)
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
      type: 'pie',
      data: {
        labels: labels,
        datasets: [{
          data: data,
          backgroundColor: colors,
          borderColor: '#fff',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { position: 'bottom' },
          tooltip: {
            callbacks: {
              label: function(context) {
                const value = context.raw
                const total = data.reduce((a,b)=>a+b,0)
                const percent = ((value/total)*100).toFixed(1)
                return `${context.label}: ${value} (${percent}%)`
              }
            }
          }
        },
        animation: { animateRotate: true, animateScale: true, duration: 1200 }
      }
    })
  }

  attachDeleteEvents() {
    // Map pour convertir resource plural en singulier
    const singularMap = { "expenses": "expense", "revenues": "revenue" }
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
          if (data.success) {
            // Recharger la page ou mettre à jour dynamiquement le tableau + chart
            window.location.reload()
          } else {
            alert("Erreur lors de la suppression !")
          }
        })
      })
    })
  }
}

