# Operating the household app

Run `bin/rails db:prepare` before starting web and worker processes. The household scheduler runs every minute in development and production; it materializes upcoming occurrences, persists due events and notifications, and dispatches durable webhook deliveries. Follow the existing Compose topology: one database preparation service and separate web/jobs processes. Never run host and container workers against the same SQLite files simultaneously.

Production forces HTTPS. Set `APP_HOST` to the deployment hostname for mail links; set `ASSUME_SSL=1` only when operating behind a trusted TLS-terminating reverse proxy. `config/deploy.yml` still contains example host/registry values and must be configured for the actual deployment. Configure VAPID public/private keys and a real HTTPS/mailto VAPID subject for browser push. Keep private keys and SQLite files outside source control. In-app reminders work without browser push.

## Health and monitoring

`/up` checks Rails boot health, not scheduler freshness. The administrator Integrations page shows the last successful household scheduler run and flags runs older than five minutes. Monitor worker failures and scheduler execution in Solid Queue, overdue undelivered `WebhookDelivery` rows, and growth of `DomainEvent`/`ApiRequest`. Integrations shows the latest 50 delivery attempts and supports replay. Idempotency records and domain events currently have no automatic retention policy.

## Backup and restore

Pause web and job writers. Back up all configured SQLite databases with SQLite's online backup facility (or copy database files only after all writers stop), Active Storage objects, and deployment secrets including persistent VAPID keys. Store backups separately with restricted access.

Restore into an isolated environment with push and webhook delivery disabled. Run `bin/rails db:prepare`, then verify household membership, task history, pet attachments, token digests, and queue state before reopening access. Do not start restored workers until outbound integrations have been reviewed: pending deliveries may be retried and consumers must deduplicate by event ID.

A production restore drill, public HTTPS endpoint delivery, and real-device push must be verified against the actual deployment; local Rails/browser tests do not establish those results.
