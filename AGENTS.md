# AGENTS.md

This file applies to the entire repository.

## Project overview

Household is a shared-responsibilities app with an optional pet module, built as a Ruby 3.4 / Rails 8 monolith using Hotwire, SQLite, Active Storage, and the default Rails authentication generator. Keep changes aligned with conventional Rails structure and the existing server-rendered UI.

The README and specification files describe both implemented and planned features. Confirm behavior against the current routes, schema, models, controllers, and tests before assuming a documented feature exists.

## Household pivot conventions

- `docs/HOUSEHOLD_SPEC.md` is the current product specification; `docs/PET_CARE.md` defines the first-party Pet Care module. `/openapi.json` is the public API contract; keep it and `docs/API.md` aligned with controller responses.
- Household access is scoped through `Current.user.households` (or the authenticated API actor). Household pets inherit membership; legacy pet memberships must never grant access to a household pet.
- Pet Care is a first-party household module represented by `HouseholdModule`; do not restore global pet navigation, standalone pet membership, or a second scheduling engine. Module-specific task data belongs in `PetCareTaskDetail`, not the core task table.
- Task HTML and API controllers share `Tasks` services. Browser task actions use session/CSRF authentication against `/api/v1`; personal tokens are only for external clients.
- Persist occurrence IDs and preserve them for assignment/title changes. Schedule edits replace future pending occurrences only. Feeding completion and inventory deduction share a transaction through `Meals::RecordFeeding`.
- API mutations require per-user idempotency keys. Recheck current household access before replaying a stored response. Tokens cannot exceed current membership or their household/scopes.
- Durable events are written inside domain transactions. Webhook jobs lease attempts before releasing the database lock for network I/O; retain DNS pinning, public-address validation, TLS verification, and disabled redirects.
- The old meal engine only serves household-less development records. Household feeding uses task occurrences; never run both reminder engines for the same pet.

## Working conventions

- Treat `ROADMAP.md` as the durable source of milestone status. Update it when a milestone starts, completes, or materially changes scope; do not rely only on conversation state.
- When work reveals an important, durable project constraint, convention, pitfall, or verification requirement that would help future contributors, add it to this `AGENTS.md` in the appropriate section. Keep additions concise and repository-specific rather than recording temporary session details.
- Use project binstubs (`bin/rails`, `bin/rubocop`, and the other scripts in `bin/`) instead of global commands.
- Keep controllers focused on HTTP concerns. Put non-trivial meal-domain behavior under `app/services/meals` and persistence rules in models.
- Scope pet-owned records through `Current.user.pets`; do not bypass authorization with unscoped finds in application code.
- Pet URLs use the opaque `public_id`; keep integer primary keys for associations and resolve pet routes through `current_user_pet!` so authorization and legacy numeric URLs remain supported.
- Preserve the application's time-zone behavior. Scheduled occurrences use the pet's time zone, while users also have their own configured time zone.
- A pet must always retain at least one caretaker and one administrator. When an administrator unlinks themselves and other caretakers remain, promote the longest-linked remaining caretaker; keep membership removal transactional.
- Pet invitations are single-use, expire after seven days, and may optionally be restricted to a normalized email address. Preserve the protected-destination return flow through both sign-in and registration.
- Notifications must remain idempotent through a stable per-user `deduplication_key`. Scheduled jobs may run repeatedly; never rely on timing alone to prevent duplicate alerts.
- In-app notifications work without push configuration. Browser delivery additionally requires `VAPID_PUBLIC_KEY` and `VAPID_PRIVATE_KEY`; never commit private VAPID material. Expired browser subscriptions should be removed during delivery. Development creates persistent keys in git-ignored `storage/development_vapid.json`; never commit that file or regenerate keys on each boot. Push UI must check subscription-save responses before reporting success, and CSS must honor `hidden` on buttons.
- Live notification streams are scoped to the signed-in user. Development uses Solid Cable so job-process broadcasts reach Puma; prepare its database with `bin/rails db:prepare`. Bulk read updates must explicitly broadcast because `update_all` skips callbacks.
- Use a real HTTPS or mailto URI for `VAPID_SUBJECT`; Apple rejects local placeholder subjects with `BadJwtToken`. A failed push subscription must not prevent attempts to the user’s other devices.
- Legacy pet-only meal schedules can only be created, edited, or removed by pet administrators. Household task schedules are collaborative. Caretakers edit their own reminders through the separate meal reminder endpoint. Weekday overrides use the occurrence date in the pet’s time zone (including delays across midnight); a null override disables that day, while a missing override retains the legacy delay.
- Personal meal reminders use `MealReminderPreference` per user and slot (missing preference means enabled with 60 minutes). Only the signed-in user may edit their preference. Keep the single per-occurrence notification key stable, honor opt-out, and suppress fed/skipped occurrences. Development scheduling requires the queue database (`bin/rails db:prepare`); Puma starts the worker and scheduler automatically. Use `SOLID_QUEUE_IN_PUMA=0` when running `bin/jobs` separately.
- The Today dashboard uses the viewer’s time zone for its day boundary and displayed times, but reminder weekday preferences and logging links use the occurrence date in the pet’s time zone. Keep its recent pending window aligned with `Meals::PublishReminders`.
- Meal reminders and unresolved-meal detection use each pet's time zone. Keep recurring jobs time-zone-aware and pass explicit times/dates in tests.
- Meal occurrences must not predate the meal slot's creation date in the pet's time zone; new schedules do not create a retroactive unresolved backlog.
- Use strong parameters through Rails `params.expect` conventions already present in the controllers.
- Pet photos use bounded square frames with `resize_to_limit` variants and `object-fit: contain`; preserve the full image rather than stretching or cropping it to card width.
- Prefer the existing Hotwire/server-rendered approach over introducing a separate frontend framework.
- Do not edit unrelated user changes or generated dependency files unless the task requires it.

## Database changes

- The pre-production database history was squashed into `20261009000000_create_housemate_baseline.rb`. Add new migrations after that baseline; do not restore the removed Pet Tracker migration chain.
- Create schema changes with Rails migrations and commit both the migration and updated `db/schema.rb`.
- Preserve foreign keys, indexes, and database-level null constraints where appropriate.
- The application uses SQLite in development and test. Do not run multiple test commands concurrently against `storage/test.sqlite3`; doing so can produce `SQLite3::BusyException` errors.
- Once the test count reaches Rails' parallelization threshold, use `PARALLEL_WORKERS=1` for local full-suite runs to keep SQLite execution sequential.

## Tests

- Use Minitest and the fixtures in `test/fixtures`.
- Add model/service tests for business rules and controller/integration tests for persistence, authorization, and response behavior.
- Use system tests for complete user-visible flows. Avoid duplicating lower-level database-count assertions inside browser tests when the controller suite already covers persistence.
- System tests run with headless Chrome by default. `SYSTEM_TEST_DRIVER=rack_test` is an optional fallback for environments without Chrome, but it is not a substitute for the final browser run.
- For system-test form setup, use the shared helpers in `test/application_system_test_case.rb`. They account for inconsistent WebDriver handling of HTML5 inputs and clicks in CI.
- Prefer direct `visit` calls when a test needs to reach a specific form. Intermediate Turbo navigation can introduce preview/replacement races before form interaction.
- Keep tests deterministic: use fixture-backed records, explicit dates/time zones where relevant, and assertions on stable user-visible outcomes.

## Verification

Run relevant checks locally before pushing. Run the test commands sequentially because they share the SQLite test database.

For a full change:

```bash
bin/rubocop
RAILS_ENV=test bin/rails db:test:prepare
bin/rails test
bin/rails test:system
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

For a focused change, run the smallest relevant test first, then the full affected suite. Examples:

```bash
bin/rails test test/controllers/pets_controller_test.rb
bin/rails test test/system/pets_test.rb
```

Before handing off, report which checks passed and clearly identify anything that could not be run.

## CI and dependencies

- GitHub Actions configuration lives in `.github/workflows/ci.yml`; keep local verification consistent with those jobs.
- Dependabot monitors Bundler and GitHub Actions dependencies weekly through `.github/dependabot.yml`.
- Treat major dependency upgrades cautiously. Review release notes and test the affected feature directly, especially Active Storage/image-processing changes.
- Do not merge or recommend merging dependency updates while required checks on the target branch are failing.

## Tooling notes

- Both Docker images need `libssl-dev` during gem installation: `web-push` depends on a native OpenSSL gem that requires development headers.

- `compose.yaml` uses `Dockerfile.dev` and bind-mounts the repository, including existing development databases and push keys in `storage/`. Do not run host and container development servers/workers simultaneously against that data. Container user/group IDs must match the host (`LOCAL_UID`/`LOCAL_GID`, default 1000); container temporary files use tmpfs.
- Compose runs `web` and `jobs` separately with `SOLID_QUEUE_IN_PUMA=0`; both wait for the one-off `db-prepare` service to succeed. Keep database preparation out of their individual startup commands to avoid concurrent migrations.

- `bin/brakeman` forces an online latest-version check and may fail in restricted or offline environments before scanning. If that happens, run `bundle exec brakeman --no-pager` and report the binstub limitation.
- If the home directory is read-only, point Bundler Audit's advisory database at a writable temporary path with `--database`; do not repurpose `HOME`.
