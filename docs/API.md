# Household API v1

The running application serves the OpenAPI contract at `/openapi.json`. Interactive completion, assignment, and reminder controls use this API with browser sessions and CSRF tokens. Ordinary Rails forms call the same domain services directly.

## Personal integrations

Open a household → Integrations → Create token. Select only the needed scopes. Tokens expire after 90 days, are displayed once, and can be revoked immediately. Store tokens in your integration's secret storage, never in browser JavaScript. A token grants access only within its household and only while its owner remains a member.

Scopes: `tasks:read` lists households, members, tasks, occurrences and personal reminder settings; `tasks:write` manages tasks and resolves occurrences; `reminders:write` changes the caller's reminder settings; `pets:read` reads pet summaries. Scopes are independent: choose both read and write when needed.

Every API mutation requires an `Idempotency-Key` of at most 200 characters. Generate a new UUID per intended action and reuse it, the exact JSON body, path, and credential on network retries. Successful responses are durably replayed. Reusing a key for another payload returns 409. Distinct requests resolving an already-resolved occurrence also return 409. Keys are scoped to the user and retained indefinitely in v1; do not reuse them across tokens.

Collections return `{ "data": [...], "page": 1, "per_page": 50 }`; keep requesting pages until `data` is empty. Individual results return `{ "data": {...} }`. Errors return `{ "error": { "code": "...", "message": "..." } }`. IDs are opaque strings. Timestamps are ISO 8601 UTC; schedules separately include a Rails time-zone name and local `HH:MM` time. Weekdays are 0 (Sunday) through 6 (Saturday).

```bash
# Set BASE_URL to your HTTPS deployment and API_TOKEN to a token from Integrations.
curl --fail-with-body -H "Authorization: Bearer $API_TOKEN" "$BASE_URL/api/v1/households"
curl --fail-with-body -H "Authorization: Bearer $API_TOKEN" "$BASE_URL/api/v1/households/$HOUSEHOLD_ID/occurrences?status=pending"
curl --fail-with-body -X PATCH \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $ACTION_UUID" \
  --data '{"occurrence":{"status":"completed"}}' \
  "$BASE_URL/api/v1/households/$HOUSEHOLD_ID/occurrences/$OCCURRENCE_ID"
```

`examples/complete_task.rb` lists pending responsibilities and optionally completes one. It uses Ruby's standard library. Household invitations, token administration, webhook configuration, and medical records remain browser workflows in v1.

## Webhooks

Household administrators register endpoints in Integrations. Supported events are `task.created`, `task.updated`, `task.archived`, `occurrence.due`, `occurrence.completed`, and `occurrence.skipped`. Endpoints receive events created after registration. Events contain references; use the authenticated API to fetch details.

```json
{"id":"opaque-event-id","type":"occurrence.completed","occurred_at":"2026-10-03T12:00:00Z","data":{"version":1,"resource_id":"opaque-occurrence-id","household_id":"opaque-household-id"}}
```

Verify `X-Webhook-Signature` (`v1=HEX`) as HMAC-SHA256 of `X-Webhook-Timestamp + "." + raw request body`, using the endpoint secret. Compare in constant time, enforce a five-minute timestamp tolerance, and deduplicate by event ID (`X-Webhook-Id`). Return 2xx after durably accepting the event. Delivery is at least once, can arrive out of order, and retries use the same event ID with a fresh timestamp/signature.

Delivery attempts run through the background queue. Failures retry up to eight attempts with exponential delays capped at six hours. Administrators can inspect errors and replay deliveries from Integrations. Disabling an endpoint or removing its owner's administrator access prevents delivery.

Only HTTPS on port 443 is supported. Destinations must resolve exclusively to public IPv4 addresses; private, loopback, link-local, reserved, IPv6, and mixed-address destinations are rejected. Resolution is checked on every attempt and the HTTP connection is pinned to a checked IP while retaining TLS hostname verification. Redirects are not followed. Use a public HTTPS relay for a local development receiver.

## Scheduling and reminders

Occurrences are persisted through the next 14 local days and extended every minute. Missed scheduler runs catch up from the saved schedule. Schedule edits replace only future pending occurrences; completed and overdue records remain. Assignment/title edits preserve occurrence IDs. One-off, daily, and selected-weekday schedules are supported. DST gaps move forward; repeated local times generate one occurrence.

A missing reminder preference inherits assignment defaults: assigned member only, or everyone for open tasks, after 60 minutes. Explicit preferences override that default. A weekday value of null disables that day's reminder; omitted values inherit the base delay. Old pending tasks remain on the dashboard, but reminders are limited to occurrences from the last two days. Each recipient receives at most one reminder per occurrence.
