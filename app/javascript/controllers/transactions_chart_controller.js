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

    const chart = new Chart(ctx, {
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
          legend: { display: false }, // on masque la légende native
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.raw
                const total = data.reduce((a,b)=>a+b,0)
                const percent = ((value/total)*100).toFixed(1)
                return `${value}`
              }
            }
          }
        },
        animation: {
          animateRotate: true,
          animateScale: true,
          duration: 1000,
          easing: "easeOutElastic"
        },
        onClick: (evt, elements) => {
          if (!elements.length) return
          const index = elements[0].index
          const category = chart.data.labels[index]
          this.toggleCategorySelection(chart, index)
          this.renderLegend(chart)
        }
      },
      plugins: [{
        id: 'customLegend',
        afterUpdate: (chart) => this.renderLegend(chart),
      }]
    })

    window[this.chartIdValue] = chart
    this.renderLegend(chart)
  }

  // Toggle la sélection d'une catégorie
  toggleCategorySelection(chart, index) {
    if (this.selectedIndexes.has(index)) {
      this.selectedIndexes.delete(index)
    } else {
      this.selectedIndexes.add(index)
    }
    this.updateChartHighlight(chart)
    this.filterBySelectedCategories(chart)
  }

  updateChartHighlight(chart) {
    const dataset = chart.data.datasets[0]

    dataset.borderColor = dataset.data.map((_, i) =>
      this.selectedIndexes.has(i) ? "rgba(7, 170, 235, 0.7)" : "#fff"
    )
    dataset.borderWidth = dataset.data.map((_, i) =>
      this.selectedIndexes.has(i) ? 4 : 2
    )
    dataset.offset = dataset.data.map((_, i) =>
      this.selectedIndexes.has(i) ? 55 : 0
    )

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
    const chart = window[this.chartIdValue]
    if (!chart) return
    this.selectedIndexes.clear()
    this.updateChartHighlight(chart)
    this.showAllRows()
    this.renderLegend(chart)
  }

  renderLegend(chart) {
    if (!this.legendContainer) return
    this.legendContainer.innerHTML = ''
    this.legendContainer.style.textAlign = 'center'
    this.legendContainer.style.marginBottom = '20px'

    // Légende des catégories
    chart.data.labels.forEach((label, index) => {
      const colorBox = document.createElement('span')
      colorBox.style.display = 'inline-block'
      colorBox.style.width = '12px'
      colorBox.style.height = '12px'
      colorBox.style.backgroundColor = chart.data.datasets[0].backgroundColor[index]
      colorBox.style.margin = '0 6px'
      colorBox.style.borderRadius = '50%'

      const labelText = document.createElement('span')
      labelText.textContent = label
      labelText.style.color = 'white'
      labelText.style.marginRight = '10px'
      labelText.style.cursor = 'pointer'

      labelText.addEventListener('click', () => {
        this.toggleCategorySelection(chart, index)
        this.renderLegend(chart)
      })

      this.legendContainer.appendChild(colorBox)
      this.legendContainer.appendChild(labelText)
    })

    // Bouton Reset sous les labels
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
