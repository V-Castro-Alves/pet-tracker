import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "amount", "credited"]
  connect() { this.element.dataset.taskActionReady = "true" }
  disconnect() { delete this.element.dataset.taskActionReady }
  async send(element, body) {
    if (!navigator.onLine) { this.messageTarget.textContent = "Connect to the internet to save changes."; return }
    element.disabled = true
    const fingerprint = JSON.stringify(body)
    if (this.pendingBody !== fingerprint) { this.pendingKey = crypto.randomUUID(); this.pendingBody = fingerprint }
    try {
      const response = await fetch(element.dataset.url, {
        method: "PATCH", credentials: "same-origin",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || "", "Idempotency-Key": this.pendingKey },
        body: fingerprint
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error?.message || "Unable to save")
      this.pendingBody = null
      this.messageTarget.textContent = "Saved"
      if (body.occurrence) window.Turbo.visit(window.location.href, { action: "replace" })
    } catch (error) { this.messageTarget.textContent = `${error.message}. Please retry.` }
    finally { element.disabled = false }
  }
  resolve(event) {
    const occurrence = { status: event.currentTarget.dataset.status }
    if (this.hasCreditedTarget) occurrence.credited_user_id = this.creditedTarget.value
    if (this.hasAmountTarget) occurrence.actual_amount_g = this.amountTarget.value
    this.send(event.currentTarget, { occurrence })
  }
  assign(event) { this.send(event.currentTarget, { task: { assignee_id: event.currentTarget.value } }) }
  reminder(event) { this.send(event.currentTarget, { reminder: { enabled: event.currentTarget.checked } }) }
}
