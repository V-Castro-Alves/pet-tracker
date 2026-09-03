import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "enable", "disable"]
  static values = { publicKey: String, createUrl: String, destroyUrl: String }

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window) || !this.publicKeyValue) {
      this.statusTarget.textContent = this.publicKeyValue ? "Push notifications are not supported by this browser." : "Push notifications are not configured on this server."
      this.enableTarget.hidden = true
      return
    }

    this.registration = await navigator.serviceWorker.ready
    this.subscription = await this.registration.pushManager.getSubscription()
    this.renderState()
  }

  async enable() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") {
      this.statusTarget.textContent = "Notification permission was not granted."
      return
    }

    this.subscription = await this.registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.decodeKey(this.publicKeyValue)
    })

    await fetch(this.createUrlValue, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ push_subscription: this.subscription.toJSON() })
    })
    this.renderState()
  }

  async disable() {
    const endpoint = this.subscription.endpoint
    await this.subscription.unsubscribe()
    await fetch(this.destroyUrlValue, {
      method: "DELETE",
      headers: this.headers(),
      body: JSON.stringify({ endpoint })
    })
    this.subscription = null
    this.renderState()
  }

  renderState() {
    const enabled = Boolean(this.subscription)
    this.statusTarget.textContent = enabled ? "Push notifications are enabled on this device." : "Push notifications are not enabled on this device."
    this.enableTarget.hidden = enabled
    this.disableTarget.hidden = !enabled
  }

  headers() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
    }
  }

  decodeKey(value) {
    const padding = "=".repeat((4 - value.length % 4) % 4)
    const base64 = (value + padding).replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), character => character.charCodeAt(0))
  }
}
