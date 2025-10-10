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
    // Gradient disponible → Bleu pastel
    // Gradient disponible → Bleu pastel doux
    const gradientAvailable = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientAvailable.addColorStop(0, "#A8C0FF");   // centre - $primary-color
    gradientAvailable.addColorStop(0.5, "#B0C7FF"); // milieu - intermédiaire
    gradientAvailable.addColorStop(1, "#8FAEFF");   // bord - $primary-hover

    // Gradient dépenses → Lavande pastel
    const gradientExpenses = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientExpenses.addColorStop(0, "#CBA6FF");   // centre - $secondary-color
    gradientExpenses.addColorStop(0.5, "#D6B8FF"); // milieu - intermédiaire
    gradientExpenses.addColorStop(1, "#E5D4FF");   // bord - $highlight-color

    // Gradient épargne → Rose / violet pastel
    const gradientSavings = ctx.getContext('2d').createRadialGradient(225, 225, 50, 225, 225, 200);
    gradientSavings.addColorStop(0, "#f7f3f4ff");    // centre - $error-color pastel rose
    gradientSavings.addColorStop(0.5, "#f7c1d4ff");  // milieu - intermédiaire
    gradientSavings.addColorStop(1, "#FF92AA");    // bord - $error-hover


    new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Trésorerie", "Dépenses", "Épargne"],
        datasets: [{
          data: [available, expenses, savings],
          backgroundColor: [gradientAvailable, gradientExpenses, gradientSavings],
          borderColor: "#B0C7FF",
          borderWidth: 2,
          hoverOffset: 30,
          hoverBorderColor: "rgba(255,255,255,0.7)",
          hoverBorderWidth: 3
        }]
      },
      options: {
        responsive: true,
        cutout: "50%",
        plugins: {
          legend: {
          position: "bottom",
          labels: {
            padding: 20,
            usePointStyle: true,
            pointStyle: "circle",
            color: "#2d3a9e",
            font: { size: 16, weight: "500" }
          }
        },
          tooltip: {
            callbacks: {
              label: function (context) {
                const value = context.raw;
                const total = context.dataset.data.reduce((a,b)=>a+b,0);
                const percent = ((value / total) * 100).toFixed(1);
                return ` ${value.toLocaleString()}€ (${percent}%)`;
              }
            }
          }
        },
        animation: {
          animateRotate: true,
          animateScale: true,
          duration: 1500,
          easing: "easeOutQuart"
        }
      }
    });
  }
}
