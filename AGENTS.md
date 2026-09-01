# AGENTS.md

This file applies to the entire repository.

## Project overview

Pet Tracker is a Ruby 3.4 / Rails 8 monolith using Hotwire, SQLite, Active Storage, and the default Rails authentication generator. Keep changes aligned with conventional Rails structure and the existing server-rendered UI.

The README and specification files describe both implemented and planned features. Confirm behavior against the current routes, schema, models, controllers, and tests before assuming a documented feature exists.

## Working conventions

- Treat `ROADMAP.md` as the durable source of milestone status. Update it when a milestone starts, completes, or materially changes scope; do not rely only on conversation state.
- When work reveals an important, durable project constraint, convention, pitfall, or verification requirement that would help future contributors, add it to this `AGENTS.md` in the appropriate section. Keep additions concise and repository-specific rather than recording temporary session details.
- Use project binstubs (`bin/rails`, `bin/rubocop`, and the other scripts in `bin/`) instead of global commands.
- Keep controllers focused on HTTP concerns. Put non-trivial meal-domain behavior under `app/services/meals` and persistence rules in models.
- Scope pet-owned records through `Current.user.pets`; do not bypass authorization with unscoped finds in application code.
- Preserve the application's time-zone behavior. Scheduled occurrences use the pet's time zone, while users also have their own configured time zone.
- A pet must always retain at least one caretaker and one administrator. When an administrator unlinks themselves and other caretakers remain, promote the longest-linked remaining caretaker; keep membership removal transactional.
- Pet invitations are single-use, expire after seven days, and may optionally be restricted to a normalized email address. Preserve the protected-destination return flow through both sign-in and registration.
- Use strong parameters through Rails `params.expect` conventions already present in the controllers.
- Prefer the existing Hotwire/server-rendered approach over introducing a separate frontend framework.
- Do not edit unrelated user changes or generated dependency files unless the task requires it.

## Database changes

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

- `bin/brakeman` forces an online latest-version check and may fail in restricted or offline environments before scanning. If that happens, run `bundle exec brakeman --no-pager` and report the binstub limitation.
- If the home directory is read-only, point Bundler Audit's advisory database at a writable temporary path with `--database`; do not repurpose `HOME`.
