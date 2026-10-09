# HouseMate

HouseMate is a collaborative household-responsibility app built with Ruby on Rails and Hotwire. Create households, invite members, assign recurring or one-off tasks, receive reminders, and keep a shared completion history.

Pet Care is an optional first-party module enabled per household. It adds household pets, specialized care tasks, feeding history, food inventory, weight, vaccine, medical, photo, and QR workflows without introducing separate membership or scheduling systems.

## Stack

- Ruby 3.4 and Rails 8
- Hotwire and server-rendered HTML
- SQLite, Solid Queue, Solid Cable, and Solid Cache
- Active Storage
- Minitest and Selenium system tests

## Local setup

```bash
bin/setup
bin/dev
```

Open `http://localhost:3000`, register an account, and create a household. Administrators can enable Pet Care from the household page.

The application can also run through `compose.yaml`. Do not run host and container servers or workers at the same time because they share databases under `storage/`.

## Verification

Run commands sequentially because the test suite shares a SQLite database:

```bash
bin/rubocop
RAILS_ENV=test bin/rails db:test:prepare
PARALLEL_WORKERS=1 bin/rails test
PARALLEL_WORKERS=1 bin/rails test:system
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

If the Brakeman binstub cannot complete its online version check, use `bundle exec brakeman --no-pager`.

## Documentation

- [Product specification](docs/HOUSEHOLD_SPEC.md)
- [Pet Care module specification](docs/PET_CARE.md)
- [API guide](docs/API.md)
- [OpenAPI contract](public/openapi.json)
- [Roadmap](ROADMAP.md)

The API uses household-scoped tokens, per-user idempotency keys for mutations, durable domain events, and signed HTTPS webhooks. `/openapi.json` is the public contract.
