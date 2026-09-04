import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.inputTarget.value = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC"
  }
}
