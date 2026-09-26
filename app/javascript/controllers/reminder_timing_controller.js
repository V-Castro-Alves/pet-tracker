import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timing", "custom"]

  connect() { this.change() }

  change() {
    this.customTarget.hidden = this.timingTarget.value !== "custom"
    this.customTarget.querySelector("input").required = !this.customTarget.hidden
  }
}
