self.addEventListener("push", (event) => {
  const payload = event.data ? event.data.json() : { title: "Pet Tracker", options: {} }
  event.waitUntil(self.registration.showNotification(payload.title, payload.options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const path = event.notification.data?.path || "/notifications"

  event.waitUntil(clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
    const existingClient = clientList.find((client) => new URL(client.url).pathname === path)
    if (existingClient && "focus" in existingClient) return existingClient.focus()
    if (clients.openWindow) return clients.openWindow(path)
  }))
})
