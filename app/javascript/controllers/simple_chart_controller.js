import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chartId: String,
    available: Number,
    expenses: Number,
    savings: Number
  }

  connect() {
    const ctx = document.getElementById(this.chartIdValue);
    if (!ctx) return;

    const available = this.availableValue || 0;
    const expenses = this.expensesValue || 0;
    const savings = this.savingsValue || 0;

    // Création de dégradés radiaux pour chaque section
    const gradientAvailable = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientAvailable.addColorStop(0, "#80adcbff");   // Menthe douce
    gradientAvailable.addColorStop(1, "#4d90b6ff");   // Menthe soutenue

    const gradientExpenses = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientExpenses.addColorStop(0, "#4db6ac");   // Dépenses
    gradientExpenses.addColorStop(1, "#00796b");   // Bord plus sombre

    const gradientSavings = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientSavings.addColorStop(0, "#6fb68aff");   // Épargne
    gradientSavings.addColorStop(1, "#80cbc4");   // Aqua clair

    new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Trésorerie", "Dépenses", "Épargne"],
        datasets: [{
          data: [available, expenses, savings],
          backgroundColor: [gradientAvailable, gradientExpenses, gradientSavings],
          borderColor: "rgba(0,0,0,0.05)",
          borderWidth: 2,
          hoverOffset: 20
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
                const value = context.raw;
                const total = context.dataset.data.reduce((a,b)=>a+b,0);
                const percent = ((value / total) * 100).toFixed(1);
                return `${context.label}: ${value.toLocaleString()}€ (${percent}%)`;
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
    });
  }
}
