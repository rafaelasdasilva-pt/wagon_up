import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.interval = setInterval(() => this.reload(), 4000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  reload() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
