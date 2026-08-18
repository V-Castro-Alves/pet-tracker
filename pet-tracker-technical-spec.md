# Pet Tracker — Technical Spec (v0.1)

Companion to `pet-tracker-spec.md` and `pet-tracker-functional-spec.md`. This document covers architecture, data model, API surface, auth, and the notification/scheduling system needed to implement v1.

---

## 1. Architecture Overview

**Stack decision: Ruby on Rails monolith using Hotwire (Turbo + Stimulus), with Turbo Native as the path to a future native app.**

- **Backend + Frontend (v1)**: a single Rails app. Rails renders the views; Turbo handles page updates/navigation without full reloads, Stimulus handles small bits of client-side interactivity (e.g. inline amount editing on the Log a Meal screen). This serves as the PWA — no separate JS frontend/API layer to build and maintain for v1.
- **Why this instead of a separate API + JS frontend**: this app is mostly forms, lists, and a dashboard — not a highly interactive SPA — so a full separate frontend would be extra overhead without much payoff. Hotwire gets a fast, responsive feel with a single codebase.
- **Path to native app (later)**: **Turbo Native** wraps the existing Rails/Turbo views in a thin native iOS/Android shell, reusing the same backend and the same server-rendered screens, with native screens only where it's actually worth it (e.g. the camera-based QR scanner). This satisfies the original "backend/frontend separation for a future native app" goal without maintaining two full frontends — the "separation" is achieved by Turbo Native's shell/bridge layer rather than a separate JSON API.
- **If a fully separate API is ever needed** (e.g. a third-party integration, or a decision later to go fully native without Turbo Native), Rails can still expose JSON endpoints alongside the HTML views for specific resources — this isn't precluded by starting with Hotwire, just not the default for v1.
- **Background jobs**: Solid Queue (Rails 8's built-in DB-backed job backend, no Redis dependency) handles the grace-period checker, vaccine due-date checker, and low-stock checks.

```
[Rails App: Controllers + Views (Turbo/Stimulus) + Models] <---> [Postgres]
                    |
             [Solid Queue background jobs]
                    |
             [Web Push (webpush gem) / later: Turbo Native push bridge]
```

### Suggested gems / tools
| Concern | Choice |
|---|---|
| Auth | Rails 8 built-in auth generator, or Devise |
| Background jobs | Solid Queue (built into Rails 8) |
| Push notifications | `webpush` gem, feeding the `PushSubscription` table below |
| QR code generation | `rqrcode` gem |
| Pet photos | Active Storage |
| PWA manifest/service worker | Rails 8's built-in PWA scaffold |
| Future native shell | Turbo Native (iOS/Android) |

---

## 2. Data Model

### User
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| email | string | unique |
| password_hash | string | (if using password auth) |
| name | string | |
| created_at | datetime | |

### Pet
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| name | string | |
| species | string | |
| breed | string | nullable |
| birthdate | date | nullable |
| sex | enum | nullable |
| photo_url | string | nullable |
| notes | text | nullable |
| qr_token | string | unique, regenerable |
| created_at | datetime | |

### PetUser (link table — flat permissions, no role field needed)
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| user_id | UUID | FK → User |
| linked_at | datetime | |

- Constraint: a `Pet` must always have ≥1 `PetUser` row (enforce in application logic — block removal of the last one).

### PetInvite
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| invite_token | string | unique |
| invited_email | string | nullable (link-based invites may not target a specific email) |
| created_by | UUID | FK → User |
| expires_at | datetime | |
| accepted_at | datetime | nullable |

### MealSlot (the schedule definition)
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| scheduled_time | time | e.g. 08:00 |
| default_amount_g | decimal | weighed-once default |
| active | boolean | soft-disable without deleting history |

### MealLog (actual occurrences)
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| meal_slot_id | UUID | FK → MealSlot |
| scheduled_for | datetime | specific date+time instance this log resolves |
| status | enum | `fed`, `skipped` |
| actual_amount_g | decimal | nullable if skipped |
| actual_time | datetime | nullable if skipped |
| logged_by_user_id | UUID | FK → User |
| created_at | datetime | |

- Uniqueness consideration: one "resolved" `MealLog` per (`meal_slot_id`, `scheduled_for`) under normal flow; a duplicate attempt should be flagged in the API response (see 3.4) rather than silently blocked, so the UI can show the warning banner.

### FoodBag
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| total_weight_g | decimal | |
| remaining_weight_g | decimal | decremented on each MealLog with status=fed |
| started_at | datetime | |
| ended_at | datetime | nullable, set when marked finished / replaced |

### WeightLog
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| weight_kg | decimal | |
| logged_at | date | |
| note | text | nullable |

### Vaccine
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| name | string | |
| date_given | date | |
| next_due_date | date | nullable |
| clinic | string | nullable |
| notes | text | nullable |

### MedicalEntry
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| pet_id | UUID | FK → Pet |
| entry_date | date | |
| title | string | nullable |
| body | text | |
| created_by | UUID | FK → User |

### PushSubscription
| Field | Type | Notes |
|---|---|---|
| id | UUID | PK |
| user_id | UUID | FK → User |
| endpoint | string | web push endpoint URL |
| keys | json | p256dh/auth keys for web push |
| created_at | datetime | |

---

## 3. Routes / Controllers (representative — not exhaustive)

With Hotwire, these are standard Rails RESTful routes rendering HTML (Turbo Stream responses for partial updates), rather than a separate JSON API. Listed here in a resource-oriented way for clarity; still maps directly onto Rails' `resources` routing conventions.

Auth
- `POST /signup`
- `POST /session` (login), `DELETE /session` (logout)

Pets — `resources :pets`
- `index` — pet list for current user
- `create` — creates pet + `PetUser` link to creator
- `show` — pet dashboard
- `update`, `destroy`

Linked users — nested under pet
- `pets/:pet_id/users` — `index`, `destroy` (blocked if last remaining user)
- `pets/:pet_id/invites` — `create`
- `invites/:invite_token/accept` — accepts invite, creates `PetUser`

Meal schedule — `pets/:pet_id/meal_slots` — `index`, `create`, `update`, `destroy` (soft delete/inactive)

Meal logging
- `pets/:pet_id/meal_logs` — `index` (history, filterable), `create`
- `pets/:pet_id/unresolved_meals` — powers the Catch-Up Prompt, oldest first
- `meal_log/:qr_token` — QR entry point controller action; resolves token → pet, checks the logged-in user is linked (redirect to login first if needed, 403 if linked check fails), renders the closest-in-time slot pre-filled for confirmation
- `create` on `meal_logs` returns a `duplicate_warning` state (via Turbo Stream, showing the warning banner in place) rather than silently creating a second entry when one already exists for that slot/date

Food inventory — `pets/:pet_id/food_bags` — `index`, `create`, `update`

Weight — `pets/:pet_id/weight_logs` — `index`, `create`

Vaccines — `pets/:pet_id/vaccines` — `index`, `create`, `update`

Medical history — `pets/:pet_id/medical_entries` — `index`, `create`, `update`

QR code
- `pets/:pet_id/qr_code` — renders/downloads the QR image/PDF encoding `/meal_log/{qr_token}`
- `pets/:pet_id/qr_code/regenerate` — invalidates old token, issues new one

Push
- `push_subscriptions` — `create`, `destroy` — registers/removes a device's web push subscription

Every pet-scoped controller action enforces authorization via a `before_action` checking the current user has a `PetUser` row for that `pet_id` (e.g. via Pundit or a simple custom check), returning a 403/redirect otherwise.

---

## 4. Auth

- Rails 8's built-in auth generator (session-based, cookie-backed) is a natural default given the Hotwire/monolith approach — no need for token-based auth since there's no separate JS frontend consuming a JSON API. Devise remains a fine alternative if more out-of-the-box features are wanted (password resets, etc.).
- The `qr_token` embedded in the printed QR code is **not** a bearer credential — it's just an identifier used to look up the pet. The actual authorization check is: "is the currently authenticated (session-based) user linked to this pet?" This means a lost/photographed QR code is not, by itself, a security hole — someone would still need a valid, logged-in session for a linked account.
- Invite links (`invite_token`) are single-use, expiring tokens tied to a specific pet; accepting one creates a `PetUser` row for the accepting (or newly created) account.
- If Turbo Native is added later, sessions still work fine — Turbo Native shares cookies/session state with the wrapped web views by design.

---

## 5. Scheduling & Notifications

### Background jobs
Implemented as Solid Queue jobs (Rails 8's built-in DB-backed job backend — no Redis needed), scheduled via `recurring.yml` or a simple cron-like trigger:
1. **Meal grace-period checker** — runs frequently (e.g. every 5–10 min). For each active `MealSlot`, if `scheduled_time + 60min` has passed for today's occurrence and no matching `MealLog` exists, mark it unresolved and enqueue a "meal unresolved" push job to all linked users.
2. **Vaccine due-date checker** — runs daily. Flags vaccines where `next_due_date` is within a configurable warning window (e.g. 7 days) or already passed, and enqueues a notification job (once per vaccine per day, not repeated every run).
3. **Food low-stock check** — event-driven: triggered right after each meal log with `status: fed` (an `after_create` callback or an explicit call from the controller/service). Decrements `remaining_weight_g` on the active `FoodBag`; if it crosses the low-stock threshold, enqueues a notification (send once per bag, not on every subsequent log, to avoid spam).

### Delivery
- v1: Web Push via the `webpush` gem and the Rails 8 PWA service worker scaffold, using `PushSubscription` records (endpoint + keys per device/user).
- Known limitation: iOS Safari's web push support is more recent/limited than Android/desktop Chrome — worth testing on real target devices early, and considering email (via Action Mailer) as a fallback channel for high-importance alerts (vaccine overdue, food empty) regardless of push reliability.
- If/when Turbo Native is added, push notifications route through native APNs/FCM via the Turbo Native bridge instead of web push — this is a delivery-layer swap, not a rework of the "when to notify" logic living in the Solid Queue jobs above.

---

## 6. QR Code Generation

- `qr_token` is a random, unique, non-guessable string (e.g. `SecureRandom.uuid` or similar) stored on `Pet`.
- QR image encodes the URL `https://<app-domain>/meal_log/{qr_token}`.
- Generate on demand (`pets/:pet_id/qr_code`) using the `rqrcode` gem; render as PNG/SVG directly, or embed in a simple printable PDF (e.g. via Prawn) with the pet's name/instructions.
- Regeneration (`pets/:pet_id/qr_code/regenerate`) creates a new `qr_token`, immediately invalidating the old code (old physical printout stops resolving).

---

## 7. Open Technical Decisions (to confirm before/while building)

- Rails 8 built-in auth generator vs. Devise.
- Authorization approach: Pundit/CanCanCan vs. simple hand-rolled `before_action` checks — given the flat permission model (no roles), a hand-rolled check may be simpler than pulling in a full authorization gem.
- Whether meal-slot occurrences are generated as rows ahead of time or computed on the fly from `MealSlot` + calendar date when checking for unresolved meals — computing on the fly is simpler and avoids pre-generating rows indefinitely into the future.
- How much of the QR/Log-a-Meal flow should use Turbo Frames/Streams for a snappier confirm experience vs. plain full-page renders (likely worth Turbo Streams given it's the most latency-sensitive interaction in the app).
- Timing of introducing Turbo Native — after v1 is stable on the web, or in parallel once core screens are settled.
