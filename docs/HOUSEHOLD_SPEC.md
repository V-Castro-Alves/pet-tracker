# Household responsibilities

The product coordinates shared household chores and optional pet care. Rails/Hotwire pages and API-backed interactions share the same domain services. Users can belong to multiple households; administrators manage membership, settings, and webhooks while all members manage responsibilities.

Tasks have one embedded schedule: one-off, daily, or selected weekdays at a named-zone local time. Multiple times use multiple tasks. Persisted occurrences retain completion actors and credited household members. Assigned responsibilities may be completed by another member. The Today dashboard groups overdue/today/upcoming work by the viewer's zone, filters by household or personal assignment, and displays recent activity.

Pet profiles belong to households, inherit access, and keep health/photo/QR/inventory features. Household feeding uses task occurrences and typed feeding entries, not legacy meal-slot scheduling. An additional feeding is an explicit separate entry. Disabling pet care hides creation and API summaries without deleting stored pet records.

The public API, authentication, events, retry semantics, and example integration are documented in API.md and public/openapi.json. External plugins run outside the application. OAuth, voice adapters, automatic rotation, monthly recurrence, custom fields, and offline writes are deferred.

The original pet-only tables and routes remain for existing repository fixtures and development records; there is no automatic migration of those records. New household pet workflows do not schedule through the legacy meal engine. This compatibility boundary must not grant access to household pets through old pet memberships.
