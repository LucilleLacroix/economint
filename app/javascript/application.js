// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "chart.js"

import "chartkick"
// Chart.js via CDN
const script = document.createElement("script")
script.src = "https://cdn.jsdelivr.net/npm/chart.js"
script.defer = true
document.head.appendChild(script)
