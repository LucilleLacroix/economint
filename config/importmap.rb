# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true

pin "chartkick", to: "https://ga.jspm.io/npm:chartkick@4.1.1/dist/chartkick.js"
pin "Chart.bundle", to: "https://cdn.jsdelivr.net/npm/chart.js"
