# Pet Tracker implementation roadmap

This file is the durable source of implementation milestone status. Product behavior and acceptance details remain in the product, functional, and technical specification files.

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
  - Per-user, per-meal grace windows and opt-out; minute-by-minute scheduling in development and production.
- [ ] PWA and production completion
  - Offline behavior, device testing, deployment configuration, backup/restore validation, accessibility, and final documentation.

## Current verification baseline

After the personal meal reminders and development scheduling changes:

- Model/controller/service suite: 116 tests, 335 assertions, all passing.
- Headless-Chrome system suite: 9 tests, 49 assertions, all passing.
- RuboCop, Brakeman, Bundler Audit, Importmap Audit, and `git diff --check` pass.

Update these counts only after a complete verification run; focused test results do not replace the baseline.
