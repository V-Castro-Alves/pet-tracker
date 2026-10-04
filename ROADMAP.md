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

## Current verification baseline

After the weekday meal reminders and push setup popup changes:

- Model/controller/service suite: 121 tests, 373 assertions, all passing.
- Headless-Chrome system suite: 14 tests, 79 assertions, all passing.
- RuboCop, Brakeman, Bundler Audit, Importmap Audit, and `git diff --check` pass.

Update these counts only after a complete verification run; focused test results do not replace the baseline.
