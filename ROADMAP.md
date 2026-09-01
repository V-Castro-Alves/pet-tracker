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
- [ ] Background jobs and notifications
  - Idempotent meal, food, and vaccine events followed by push subscription and delivery support.
- [ ] PWA and production completion
  - Offline behavior, device testing, deployment configuration, backup/restore validation, accessibility, and final documentation.

## Current verification baseline

After the health-record milestone:

- Model/controller/service suite: 92 tests, 237 assertions, all passing.
- Headless-Chrome system suite: 6 tests, 34 assertions, all passing.
- RuboCop, Brakeman, Bundler Audit, Importmap Audit, and `git diff --check` pass.

Update these counts only after a complete verification run; focused test results do not replace the baseline.
