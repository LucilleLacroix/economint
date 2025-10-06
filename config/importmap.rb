# Pin npm packages by running ./bin/importmap
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true

# Chartkick global via JSPM
pin "chartkick", to: "https://ga.jspm.io/npm:chartkick@4.1.1/dist/chartkick.js"

# NE PAS PIN Chart.js pour importmap car on utilise le CDN global
# pin "chart.js", to: ...
