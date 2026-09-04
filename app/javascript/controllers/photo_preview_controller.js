import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "placeholder"]

  show() {
    const [file] = this.inputTarget.files
    if (!file) return

    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
    this.previewUrl = URL.createObjectURL(file)
    this.imageTarget.src = this.previewUrl
    this.imageTarget.hidden = false
    if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
  }

  disconnect() {
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
  }
}
