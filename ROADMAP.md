# Household responsibilities roadmap

The current product and API contracts are in `docs/HOUSEHOLD_SPEC.md`, `docs/PET_CARE.md`, `docs/API.md`, and `public/openapi.json`. Milestone status here is authoritative.

## Pivot milestones

- [ ] HouseMate household-first reset — **in progress**
  - [x] Rename the product to HouseMate and make collaborative household tasks the primary experience.
  - [x] Replace the global pet area and `pets_enabled` flag with a household-scoped, first-party Pet Care module.
  - [x] Remove the standalone Pet Tracker compatibility layer, rebuild a single clean database baseline, and household-scope all retained pet data.
  - [ ] Refresh navigation, household settings, task creation, responsive UI, API documentation, and verification around the new model.

- [x] Household foundation
  - Household membership, administrators, seven-day single-use invitations, registration return flow, transactional removal and successor promotion, optional pet module, and onboarding.
- [x] Tasks, persisted occurrences, and first-party API
  - One-off/daily/weekday schedules, assignments, completion attribution, history, time-zone/DST behavior, API-backed completion/assignment/reminder controls, session/CSRF authentication, and durable mutation idempotency.
- [x] Shared reminders and optional pet care
  - Personal delay/weekday settings and opt-outs, scheduled notifications, household pet authorization, task-based feeding, atomic inventory deductions, additional feeding records, retained health/photo/QR workflows, and user-scoped live refresh.
- [x] External integrations
  - Expiring scoped token digests and revocation, transactional events, signed public-HTTPS webhooks, retries/replay/diagnostics, scheduler health, OpenAPI route coverage, and a standalone Ruby integration example.
- [ ] Production launch verification
  - Local Chrome flows, responsive checks, security audits, concurrent completion, and isolated SQLite restore are verified.
  - Still requires an actual production host/registry configuration, live HTTPS verification, real-device push checks, and a production backup/restore drill including Active Storage and deployment secrets. No deployment or real-device delivery was performed during this pivot.

## Current verification baseline — 2026-10-03

- Rails suite: **154 tests, 515 assertions**, all passing (`PARALLEL_WORKERS=1 bin/rails test`).
- Real headless-Chrome suite: **19 tests, 139 assertions**, all passing (`PARALLEL_WORKERS=1 bin/rails test:system`).
- Chrome covered two household members, session-authenticated API actions with CSRF enabled, task/token/pet forms, and 320/390/768/1280px layouts without horizontal overflow.
- RuboCop: **192 files**, no offenses. Rails autoloading and `git diff --check` pass.
- Brakeman direct scan: **0 errors, 0 security warnings**. The repository binstub stops at its latest-version gate (installed 8.0.6 versus 8.1.0), so the scan used `bundle exec brakeman --no-pager`.
- Bundler Audit and Importmap Audit: no known vulnerabilities. Bundler's advisory database was placed in `/tmp/pet-tracker-advisory-db`.
- Isolated simultaneous feeding completion: one success, one conflict, one feeding record/event, and one 100g inventory deduction.
- Isolated SQLite backup/restore: integrity, foreign keys, relevant table counts, and completed occurrence history passed. This does not verify production object storage or secrets recovery.

## Compatibility boundary

The original pet-only compatibility boundary is being retired by the HouseMate household-first reset. The application has no production data, so legacy standalone pet records and migrations will be removed rather than migrated.

Webhook destinations currently require public IPv4 HTTPS on port 443. OAuth/voice adapters, hosted plugins, automatic rotation, custom fields, monthly recurrence, and offline writes remain deferred.

## Historical Pet Tracker milestones

# Pet Tracker implementation roadmap

This file is the durable source of implementation milestone status. Current Pet Care behavior and invariants are consolidated in `docs/PET_CARE.md`; the milestones below preserve the history of the former standalone product.

## Milestones

- [x] Foundation and authentication
  - Registration, sessions, password reset, authenticated application shell, user time zones, and PWA entry routes.
- [x] Pet profiles and authorization
  - Pet ownership memberships, administrator boundaries, Active Storage photos, secure QR tokens, and cross-user isolation.
- [x] Meal schedules
  - Daily slots, default serving amounts, active-slot uniqueness, and soft removal.
- [x] Meal logging and history
  - Time-zone-aware occurrences, fed/skipped resolution, duplicate confirmation, unresolved-meal selection, filters, and history.
- [x] Food inventory
  - Active bag lifecycle, transactional consumption, low-stock state, remaining-day estimates, and bag history.
- [x] QR-code meal entry
  - Printable/downloadable SVG, login return flow, membership enforcement, administrator-only regeneration, and browser coverage.
- [x] Invitations and linked-user management
  - Expiring single-use invites, acceptance through authentication, administrator removal, and safe self-unlinking.
- [x] Weight, vaccine, and medical records
  - CRUD screens, dashboard summaries, due-state helpers, and weight trend presentation.
- [x] Background jobs and notifications
  - Idempotent meal, food, and vaccine events followed by push subscription and delivery support.
- [x] Personal meal reminders
  - Per-user, per-meal grace windows and opt-out; minute-by-minute scheduling in development and production. Development Puma automatically starts the worker and scheduler.
- [x] Device push setup reliability
  - Persistent development keys, clear setup errors, and confirmed device registration. Browser setup tests use simulated push APIs; actual device delivery remains part of device testing.
- [x] Live notifications and Apple push delivery
  - User-scoped Turbo updates, cross-process development broadcasts, and a valid VAPID contact URI. Apple accepted a test push and receipt on the iPhone was confirmed.
- [x] Weekday meal reminders
  - Admin-only meal schedules, personal weekday timing and custom delays, and device push setup prompts.
- [x] Mobile-first frontend refresh
  - Compact, proportional pet photos, persistent navigation, accessible touch controls, and meal-first pet profiles.
  - Host Chrome verified navigation and overflow at 320/390/768/1280px. Rails suite: 121 tests, 373 assertions passed. Standard system suite is blocked by container ChromeDriver startup; rack-test fallback does not pass the browser-dependent suite.
- [x] Daily-care dashboard
  - All-pet personal meal reminders grouped by due/upcoming, with pet creation moved to the pet directory. Honors personal opt-outs, pet-local occurrence dates, and fed/skipped records.
  - Rails suite: 129 tests, 405 assertions passed; lint and security audits passed. Host Chrome verified responsive layouts, exact meal links, reminder removal after logging, and secondary pet creation. Full Selenium suite remains unverified due to the container ChromeDriver limitation above.
- [ ] PWA and production completion
  - Offline behavior, device testing, deployment configuration, backup/restore validation, accessibility, and final documentation.

## Historical verification baseline

After the weekday meal reminders and push setup popup changes:

- Model/controller/service suite: 121 tests, 373 assertions, all passing.
- Headless-Chrome system suite: 14 tests, 79 assertions, all passing.
- RuboCop, Brakeman, Bundler Audit, Importmap Audit, and `git diff --check` pass.

Update these counts only after a complete verification run; focused test results do not replace the baseline.
