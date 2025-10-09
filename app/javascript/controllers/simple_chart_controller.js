import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chartId: String,
    available: Number,
    expenses: Number,
    savings: Number
  }

  connect() {
    const ctx = document.getElementById(this.chartIdValue)
    if (!ctx) return

    const available = this.availableValue || 0
    const expenses = this.expensesValue || 0
    const savings = this.savingsValue || 0

    const styles = getComputedStyle(document.documentElement)
    const colorAvailable = styles.getPropertyValue("--color-available").trim()
    const colorExpenses = styles.getPropertyValue("--color-expenses").trim()
    const colorSavings = styles.getPropertyValue("--color-savings").trim()
    const colorBorder   = styles.getPropertyValue("--color-chart-border").trim()

    new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Trésorerie", "Dépenses", "Épargne"],
        datasets: [{
          data: [available, expenses, savings],
          backgroundColor: [colorAvailable, colorExpenses, colorSavings],
          borderColor: colorBorder, 
          borderWidth: 2,
          hoverOffset: 15
        }]
      },
      options: {
        responsive: true,
        cutout: "60%",
        plugins: {
          legend: { position: "bottom" },
          tooltip: {
            callbacks: {
              label: function (context) {
                const value = context.raw
                const total = context.dataset.data.reduce((a, b) => a + b, 0)
                const percent = ((value / total) * 100).toFixed(1)
                return `${context.label}: ${value.toLocaleString()}€ (${percent}%)`
              }
            }
          }
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
