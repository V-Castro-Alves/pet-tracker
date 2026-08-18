# Pet Tracker — Product Spec

## 1. Overview

Pet Tracker is a web app that lets pet owners and caretakers log and stay on top of the important, recurring parts of caring for a pet: feeding, food supply, weight, vaccines, and medical history. A pet can be shared across multiple users (e.g. partners, roommates, family members, pet sitters), and any of them can log activity for that pet.

The signature feature is a **printable QR code** that lives next to the pet's food bag, letting a caretaker log a meal in a couple of taps instead of opening the app and navigating to a form.

### Goals
- Make logging a meal fast enough that people actually do it every time.
- Make sure feeding doesn't get missed or duplicated when multiple people care for the same pet.
- Give an early warning before pet food runs out.
- Keep a simple, always-available record of vaccines and medical history.

### Non-goals (for v1)
- Structured medical records (diagnoses, vet visit forms, lab results) - connected directly to vets.
- Native mobile app — PWA only (although using Rails 8 it is possible to create a native mobile app).
- Barcode/product lookup for food brands.

---

## 2. Users & Roles

A pet can have multiple linked users. The user that created the pet profile by default takes the roles of administrator (which is the only role that can invite and remove other users linked to the pet) — all the users linked to the pet can log meals, edit the pet profile, manage vaccines and medical history.

- A pet must have at least one linked user at all times (can't remove the last remaining user).
- Invites happen via email or shareable link; the invited user gets access once they accept.
- Any linked user can unlink themselves.
- Only the administrator of the pet can remove any other linked user at any time.

---

## 3. Core Features

### 3.1 Pet Profiles
- Name, species, breed, birthdate/age, photo, sex, notes.
- List of linked users and their roles.
- A pet's dashboard shows: next scheduled meal, current food level, last weight entry, upcoming/overdue vaccines.

### 3.2 Meal Logging
- Define a **feeding schedule** per pet: number of meals/day, target time for each, and a **default amount** (weight, e.g. grams) per meal (optional).
- The default amount is weighed and entered **once** when setting up (or adjusting) the schedule. Every subsequent log for that meal slot uses this default automatically — the user doesn't need to weigh food each time. The amount remains editable at log time for the occasional exception (e.g. vet put the pet on a temporary diet).
- **Logging a meal** records: which scheduled meal it was, actual time, actual amount (defaults to the pre-set weight, editable), and **which user logged it**.
- **Reminders**: push notification at scheduled meal time to all linked users; reminder auto-clears for everyone once any user logs that meal (prevents double-feeding and redundant notifications).
- **Duplicate protection**: if a second user tries to log the same meal slot after it's already been logged, show a clear warning ("Already logged by [name] at [time]") before allowing a duplicate entry — helps catch accidental double-feeding.
- **Missed meal detection**: if no log exists by [scheduled time + grace period, 60 min] and the meal isn't otherwise resolved, mark the meal slot as "unresolved" and notify all linked users.
- **Catch-up flow**: when a user opens the app and there's an older unresolved meal slot (e.g. it's evening and lunch was never marked), the app surfaces that oldest unresolved slot first and asks the user to resolve it — "Fed (just forgot to log)" or "Skipped" — before treating other meals as current. When logging trough scanning the QRCode if there are older meals unresolved, the app will first ask the user to resolve the closest-in-time unresolved slot before proceeding to log the current one.
- Meal history view per pet (list/calendar), filterable by date range and by which user logged it.

### 3.3 QR Code Meal Logging
- Each pet gets a **unique** printable QR code encoding a pet-specific token (`/meal-log/{pet-token}`), ready to print and tape near that pet's food bag. Not a generic/shared URL — the code identifies which specific pet it belongs to, which is what lets a multi-pet household scan the right code and skip picking a pet.
- Scanning the code (via phone camera or in-app scanner):
  - If not logged in, prompts login first.
  - Backend checks that the logged-in user is linked to the pet the token maps to; if not authorized, shows an error rather than a log form.
  - If authorized, opens directly to that pet's "Log a meal" screen, pre-filled with the next scheduled/overdue meal and its default amount.
  - User confirms (or edits the amount) and submits in one or two taps.
- The token itself is just an identifier, not a secret — access control is enforced by the login + linked-user check, not by the token being hard to guess.

### 3.4 Food Inventory Tracking
- User enters the total weight of a new bag when opened ("Started new bag: 3.5 kg").
- Each logged meal subtracts its amount from the remaining bag weight.
- When remaining weight drops below a threshold (e.g. 15% or a user-set amount), send a "running low — buy more food" notification.
- Show current estimated remaining weight and estimated days left (based on average daily consumption) on the pet dashboard.
- History of bags (start date, size, end date) for reference.

### 3.5 Pet Weight Tracking
- Manual log entries: date + weight (+ optional note).
- Simple chart/trend view over time.
- Optional: reminder to log weight periodically (e.g. monthly) — nice-to-have, not core.

### 3.6 Vaccines
- Log vaccine records: name/type, date given, next due date, vet/clinic (optional), notes.
- Next due date is entered manually by the user, based on what the vet told them (no vet system integration — this is user-reported data).
- Dashboard/alert when a vaccine's next-due date is approaching or overdue.

### 3.7 Medical History
- Freeform text log per entry, with a date and optional title (e.g. "Ear infection — March 2026").
- Entirely user-typed, with no connection to vets or external medical systems — just a personal record the user maintains themselves.
- Chronological list per pet, most recent first.
- (Future: convert to structured fields — visit date, vet, reason, diagnosis, treatment, attachments — and possibly vet-facing integration. Out of scope for now.)

---

## 4. Notifications & Architecture

**Decision:** v1 ships as a **PWA**, built with Rails 8 Hotwire +Stimulus stack and turbo-ios gem to allow for easy migration to a native mobile app in the future.

Types of notifications needed:
1. Upcoming meal reminder.
2. Meal skipped alert.
3. Food running low.
4. Vaccine due/overdue.
