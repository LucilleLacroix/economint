import { Controller } from "@hotwired/stimulus"

// Contrôleur pour le graphique et interactions avec le tableau
export default class extends Controller {
  static values = {
    resource: String,       // "expenses" ou "revenues"
    chartId: String,        // ID du canvas
    categories: Array,      // JSON des catégories
    dataByCategory: Object  // Données agrégées par catégorie
  }

  connect() {
    this.canvas = document.getElementById(this.chartIdValue)
    if (!this.canvas) return

    this.table = document.querySelector(".styled-table tbody")
    this.legendContainer = document.getElementById(`${this.chartIdValue}Legend`)
    this.selectedIndexes = new Set() // Multi-sélection

    this.renderChart(this.dataByCategoryValue)
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

    this.chart = new Chart(ctx, {
      type: "pie",
      data: {
        labels,
        datasets: [{
          data,
          backgroundColor: colors,
          borderColor: "#B0C7FF",
          borderWidth: 2,
          hoverOffset: 55,
          hoverBorderColor: "rgba(7, 170, 235, 0.7)",
          hoverBorderWidth: 3
        }]
      },
      options: {
        responsive: true,
        layout: { padding: { top: 35, bottom: 30, left: 0, right: 0 } },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.raw
                return `${value}`
              }
            }
          }
        },
        animation: { animateRotate: true, animateScale: true, duration: 1000, easing: "easeOutElastic" },
        onClick: (evt, elements) => {
          if (!elements.length) return
          const index = elements[0].index
          this.toggleCategorySelection(this.chart, index)
          this.renderLegend(this.chart)
        }
      },
      plugins: [{
        id: 'customLegend',
        afterUpdate: (chart) => this.renderLegend(chart)
      }]
    })

    window[this.chartIdValue] = this.chart
    this.renderLegend(this.chart)
  }

  updateChartData(newData) {
  // Détruire le chart existant s’il existe
  if (window[this.chartIdValue] instanceof Chart) {
    window[this.chartIdValue].destroy()
  }

  // 🔥 Important : forcer un rafraîchissement du canvas context
  this.canvas = document.getElementById(this.chartIdValue)
  if (!this.canvas) return

  // Re-rendre le graphique avec les nouvelles données
  this.renderChart(newData)
}


  // Toggle sélection
  toggleCategorySelection(chart, index) {
    if (this.selectedIndexes.has(index)) this.selectedIndexes.delete(index)
    else this.selectedIndexes.add(index)
    this.updateChartHighlight(chart)
    this.filterBySelectedCategories(chart)
  }

  updateChartHighlight(chart) {
    const dataset = chart.data.datasets[0]
    dataset.borderColor = dataset.data.map((_, i) => this.selectedIndexes.has(i) ? "rgba(7, 170, 235, 0.7)" : "#fff")
    dataset.borderWidth = dataset.data.map((_, i) => this.selectedIndexes.has(i) ? 4 : 2)
    dataset.offset = dataset.data.map((_, i) => this.selectedIndexes.has(i) ? 55 : 0)
    chart.update()
  }

  filterBySelectedCategories(chart) {
    if (!this.table) return
    const rows = this.table.querySelectorAll("tr")
    const selectedLabels = Array.from(this.selectedIndexes).map(i => chart.data.labels[i])
    rows.forEach(row => {
      const catCell = row.children[0]?.textContent.trim()
      row.style.display = selectedLabels.length === 0 || selectedLabels.includes(catCell) ? "" : "none"
    })
  }

  showAllRows() {
    if (!this.table) return
    this.table.querySelectorAll("tr").forEach(row => row.style.display = "")
  }

  resetFilter() {
    if (!this.chart) return
    this.selectedIndexes.clear()
    this.updateChartHighlight(this.chart)
    this.showAllRows()
    this.renderLegend(this.chart)
  }

  renderLegend(chart) {
    if (!this.legendContainer) return
    this.legendContainer.innerHTML = ''
    this.legendContainer.style.textAlign = 'center'
    this.legendContainer.style.marginBottom = '20px'

    chart.data.labels.forEach((label, index) => {
      const colorBox = document.createElement('span')
      colorBox.style.cssText = 'display:inline-block;width:14px;height:12px;margin:0 6px;border-radius:50%;border:1px solid white;box-sizing:border-box;background-color:' + chart.data.datasets[0].backgroundColor[index]

      const labelText = document.createElement('span')
      labelText.textContent = label
      labelText.style.cssText = 'color:white;margin-right:10px;cursor:pointer'
      labelText.addEventListener('click', () => { this.toggleCategorySelection(chart, index); this.renderLegend(chart) })

      this.legendContainer.appendChild(colorBox)
      this.legendContainer.appendChild(labelText)
    })

    const resetBtn = document.createElement('button')
    resetBtn.innerHTML = '<i class="fas fa-undo-alt"></i>'
    resetBtn.className = 'btn btn-success'
    resetBtn.style.marginTop = '8px'
    resetBtn.addEventListener('click', () => this.resetFilter())
    this.legendContainer.appendChild(document.createElement('br'))
    this.legendContainer.appendChild(resetBtn)
  }

  attachDeleteEvents() {
    const singularMap = { expenses: "expense", revenues: "revenue" }
    const singularResource = singularMap[this.resourceValue] || this.resourceValue

    document.querySelectorAll(`.delete-${singularResource}`).forEach(btn => {
      btn.addEventListener("click", (event) => {
        event.preventDefault()
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
            // Supprime la ligne du tableau
            const row = document.getElementById(`${singularResource}_${id}`)
            if (row) row.remove()

            // Met à jour le chart
            this.updateChartData(data.data_by_category)
          } else {
            alert("Erreur lors de la suppression !")
          }
        })
      })
    })
  }
}
