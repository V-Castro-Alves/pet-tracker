import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "enable", "disable"]
  static values = { publicKey: String, createUrl: String, destroyUrl: String }

  async connect() {
    this.enableTarget.disabled = true
    this.disableTarget.hidden = true
    if (!this.publicKeyValue) {
      this.statusTarget.textContent = "Push notifications are not configured on this server."
      this.enableTarget.hidden = true
      return
    }
    if (!window.isSecureContext || !("serviceWorker" in navigator) || !("PushManager" in window) || !("Notification" in window)) {
      this.statusTarget.textContent = "This browser cannot enable push here. On iPhone or iPad, add Pet Tracker to your Home Screen and open it there. Otherwise, use a browser that supports push over HTTPS."
      this.enableTarget.hidden = true
      return
    }

    try {
      await this.withTimeout(navigator.serviceWorker.register("/service-worker.js"))
      this.registration = await this.withTimeout(navigator.serviceWorker.ready)
      this.subscription = await this.registration.pushManager.getSubscription()
      // A browser subscription alone does not prove it was saved for this account.
      if (this.subscription) await this.saveSubscription()
      this.renderState()
    } catch (error) {
      this.showError(error)
    } finally {
      this.enableTarget.disabled = !this.registration
    }
  }

  async enable() {
    if (!this.registration) return
    this.enableTarget.disabled = true
    try {
      // Request permission directly from the click, before any other await.
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        this.statusTarget.textContent = "Notification permission was not granted. Allow notifications in your browser's site settings, then try again."
        return
      }
      this.statusTarget.textContent = "Enabling notifications…"
      this.subscription = await this.withTimeout(this.registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.decodeKey(this.publicKeyValue)
      }))
      await this.saveSubscription()
      this.renderState()
    } catch (error) {
      this.showError(error)
    } finally {
      this.enableTarget.disabled = false
    }
  }

  async disable() {
    if (!this.subscription) return
    this.disableTarget.disabled = true
    try {
      await this.request(this.destroyUrlValue, "DELETE", { endpoint: this.subscription.endpoint })
      await this.subscription.unsubscribe()
      this.subscription = null
      this.renderState()
    } catch (error) {
      this.showError(error)
    } finally {
      this.disableTarget.disabled = false
    }
  }

  async saveSubscription() {
    await this.request(this.createUrlValue, "POST", { push_subscription: this.subscription.toJSON() })
  }

  async request(url, method, body) {
    const response = await fetch(url, {
      method,
      headers: this.headers(),
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15000)
    })
    if (!response.ok || response.redirected) {
      throw new Error("Could not save device settings. Refresh the page, sign in if needed, and try again.")
    }
  }

  async withTimeout(promise) {
    let timer
    try {
      return await Promise.race([
        promise,
        new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error("Device setup timed out. Reload the page and try again.")), 15000)
        })
      ])
    } finally {
      clearTimeout(timer)
    }
  }

  showError(error) {
    this.statusTarget.textContent = `Push setup failed: ${error.message || "Please reload and try again."}`
    this.enableTarget.hidden = false
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
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
    }
  }

  decodeKey(value) {
    const padding = "=".repeat((4 - value.length % 4) % 4)
    const base64 = (value + padding).replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), character => character.charCodeAt(0))
  }
}
