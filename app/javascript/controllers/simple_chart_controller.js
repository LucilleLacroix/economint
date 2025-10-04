import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chartId: String,
    revenues: Number,
    expenses: Number
  }

  connect() {
    const ctx = document.getElementById(this.chartIdValue)
    if (!ctx) return

    const totalRevenues = this.revenuesValue || 0
    const totalExpenses = this.expensesValue || 0
    const balance = totalRevenues - totalExpenses

    new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Revenus", "Dépenses"],
        datasets: [{
          data: [totalRevenues, totalExpenses],
          backgroundColor: ["#cc2ebfff", "#7140ccff"],
          borderColor: "#fff",
          borderWidth: 2,
          hoverOffset: 20
        }]
      },
      options: {
        responsive: true,
        cutout: "55%",
        plugins: {
          legend: { position: "bottom" },
          tooltip: {
            callbacks: {
              label: function(context) {
                const value = context.raw
                const total = context.dataset.data.reduce((a,b)=>a+b,0)
                const percent = ((value/total)*100).toFixed(1)
                return `${context.label}: ${value}€ (${percent}%)`
              }
            }
          },
         

        },
        animation: {
          animateRotate: true,
          animateScale: true,
          duration: 1200
        }
      }
    })
  }
}
