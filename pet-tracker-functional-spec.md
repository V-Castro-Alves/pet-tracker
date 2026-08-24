# Pet Tracker — Functional Spec

This document breaks the product spec down into concrete screens, flows, and edge cases. It assumes the decisions in `pet-tracker-spec.md` (roles, PWA, per-pet QR tokens, 60-min grace period, weigh-once meal amounts).

---

## 1. Screen Inventory

| # | Screen | Purpose |
|---|---|---|
| 1 | Login / Sign up | Auth entry point |
| 2 | Pet List (Home) | List of all pets the user is linked to |
| 3 | Pet Dashboard | Single pet's overview: next meal, food level, weight, vaccine/medical alerts |
| 4 | Add / Edit Pet | Create or edit a pet's profile |
| 5 | Manage Linked Users | View/invite/remove users linked to a pet (if administrator role)|
| 6 | Meal Schedule Setup | Define number of meals/day, times, default amount per meal |
| 7 | Log a Meal | Confirm/edit a meal log (reached via QR scan or manually) |
| 8 | Meal History | List/calendar of past meal logs for a pet |
| 9 | Catch-Up Prompt | Resolves older unresolved meal slots ("fed but not logged" / "skipped") |
| 10 | QR Code Page | Displays/downloads/prints the pet's unique QR code |
| 11 | Food Bag Setup | Start a new bag (enter total weight) |
| 12 | Food Inventory View | Current remaining weight, estimated days left, bag history |
| 13 | Weight Log | Add/view pet weight entries + trend |
| 14 | Vaccine List | View vaccines, due dates, add/edit a vaccine record |
| 15 | Medical History | Chronological freeform entries, add/edit |
| 16 | Notification Settings | (Optional v1) manage push permission / preferences |

---

## 2. Screen Details

### 2.1 Login / Sign up
- Fields: email, password (or magic link — TBD by tech spec).
- On success → Pet List.
- If arriving via a QR scan link while logged out, complete login then redirect straight into the Log a Meal screen for that pet/token (see 3.3).

### 2.2 Pet List (Home)
- Grid/list of pet cards: photo, name, next meal time, food level badge (OK / Low / Empty), any active alert (vaccine due, unresolved meal).
- "Add Pet" action.
- Tapping a pet → Pet Dashboard.

### 2.3 Pet Dashboard
- Header: photo, name, species/breed, age.
- Next scheduled meal (time, default amount) with a manual "Log now" button.
- Food inventory summary: remaining weight, estimated days left, "Buy more" indicator if low.
- Latest weight entry + link to trend.
- Vaccine alerts (upcoming/overdue), linking to Vaccine List.
- Recent medical history snippet, linking to full Medical History.
- Access to: Meal Schedule Setup, QR Code Page, Manage Linked Users, Food Bag Setup, Edit Pet.

### 2.4 Add / Edit Pet
- Fields: name, species, breed (optional), birthdate or approximate age, sex, photo, notes.
- Save → Pet Dashboard (new pets go straight into Meal Schedule Setup as a next step, since a pet without a schedule can't be logged or reminded).
- Delete pet: requires confirmation; see edge cases (4.1).

### 2.5 Manage Linked Users
- List of users currently linked (name/email).
- "Invite" action → generates an invite link or sends an email invite. (for administrator)
- "Remove" action next to each user (disabled/hidden for the last remaining user — see edge case 4.2). (for administrator)

### 2.6 Meal Schedule Setup
- Set number of meals/day.
- For each meal slot: time, default amount (grams). Amount is entered once here (the "weigh once" step) and reused for every future log of that slot.
- Editing an existing slot's default amount only affects future logs, not past history.
- Save → Pet Dashboard.

### 2.7 Log a Meal
- Reached via: QR scan, manual "Log now" on dashboard, or the Catch-Up Prompt.
- Shows: pet name, which meal slot, pre-filled amount (from schedule default), timestamp (defaults to now, editable).
- Actions: "Confirm fed" (submits log), "Edit amount" (inline field), "Mark skipped" instead of fed.
- If this meal slot was already logged by someone else, show a warning banner: "Already logged by [name] at [time]" with the log details, and require an extra confirmation tap to log again (duplicate protection).
- On submit → success confirmation, then back to Pet Dashboard or closes (if opened from QR scan, likely closes/minimizes back to home screen).

### 2.8 Meal History
- List or calendar view, most recent first.
- Each entry: meal slot, scheduled time, actual time, amount, status (Fed / Skipped / Fed-late), who logged it.
- Filters: date range, logged-by user.

### 2.9 Catch-Up Prompt
- Triggered when the user opens the app (or a pet's dashboard) and there's an older meal slot with no resolution (not logged, not marked skipped) past its grace period.
- Shown before/above other content until resolved.
- Options: "It was fed (just forgot to log)" → opens Log a Meal pre-filled with that slot, timestamp editable; "It was skipped" → marks Skipped directly.
- If multiple older unresolved slots exist, resolve oldest first, one at a time.

### 2.10 QR Code Page
- Displays the pet's unique QR code (encodes `/meal-log/{pet-token}`).
- "Download" (image/PDF) and "Print" actions.
- Short instructions: "Print this and place it near [pet]'s food."
- Option to regenerate the token (invalidates the old code) — see edge case 4.3.

### 2.11 Food Bag Setup
- "Start new bag": enter total weight (grams/kg).
- Shows current bag (if any) with remaining estimate, and a "this bag is finished / starting a new one" action.

### 2.12 Food Inventory View
- Remaining weight, estimated days left (based on recent average daily consumption).
- Low-stock threshold indicator.
- History table of past bags (start date, size, end date, computed duration).

### 2.13 Weight Log
- Add entry: date, weight, optional note.
- List of past entries + simple line chart over time.

### 2.14 Vaccine List
- List of vaccines: name, date given, next due date, vet/clinic, notes.
- Add/edit form matches these fields.
- Visual flag for due-soon / overdue entries.

### 2.15 Medical History
- List of freeform entries: date, optional title, text body.
- Add/edit form; entries are user-authored only (no vet integration).

### 2.16 Notification Settings (optional for v1)
- Toggle push notifications on/off.
- Possibly per-category toggles (meal reminders, food low, vaccine due) — nice-to-have, not required for launch.

---

## 3. Key Flows

### 3.1 Onboarding / First Pet
1. Sign up → Pet List (empty state: "Add your first pet").
2. Add Pet → Meal Schedule Setup (prompted immediately) → Food Bag Setup (prompted, optional/skippable) → Pet Dashboard.
3. From dashboard, user can go generate the QR Code and invite other linked users.

### 3.2 Invite a Household Member
1. From Manage Linked Users, generate invite link or send email invite.
2. Recipient opens link → if they don't have an account, sign up first → automatically linked to the pet with full access once accepted.

### 3.3 QR Scan → Log a Meal
1. User scans physical QR code with phone camera.
2. Opens `/meal-log/{pet-token}` in the PWA.
3. If not logged in → login screen → on success, continue to step 4.
4. Backend checks the logged-in user is linked to the pet mapped by `{pet-token}`.
   - Not linked → show access-denied message.
   - Linked → continue.
5. Determine the closest-in-time scheduled meal slot for that pet (could be slightly before or after "now").
6. Show Log a Meal screen pre-filled with that slot and its default amount.
7. User confirms (or edits) → log saved, reminder for that slot cleared for all linked users.

### 3.4 Missed Meal → Catch-Up
1. Scheduled meal time + 60 min passes with no log.
2. Backend marks the slot "unresolved" and sends a notification to all linked users ("Was [pet] fed at [time]?").
3. Next time any linked user opens the app, the Catch-Up Prompt appears for that slot until resolved.
4. Resolution (fed-but-unlogged, or skipped) updates Meal History accordingly.

### 3.5 Food Running Low
1. Each meal log subtracts its amount from the current bag's remaining weight.
2. When remaining weight crosses the low-stock threshold, send a notification to all linked users and show a persistent badge on the Pet Dashboard / Food Inventory View.
3. User starts a new bag via Food Bag Setup, which resets the remaining-weight calculation.

### 3.6 Vaccine Due
1. User adds a vaccine record with a next-due date (from the vet).
2. Backend checks due dates on a schedule (e.g. daily) and flags/notifies when a due date is approaching or passed.
3. Alert shows on Pet Dashboard and Vaccine List until the user logs the new vaccine (which resolves/replaces the alert) or dismisses it.

---

## 4. Edge Cases

1. **Deleting a pet.** Requires confirmation; deletion removes the pet for *all* linked users, not just the requester. Require a typed confirmation (e.g. pet's name) given the destructive, shared-impact nature. (only the admin can do that)
2. **Removing the last linked user.** Not allowed — a pet must always have at least one linked user. If the last user wants to stop tracking a pet entirely, that action should be framed as "delete this pet" instead, with a clear warning.
3. **Regenerating a QR token.** If a code is lost, damaged, or the user is worried about it being copied, allow generating a new token for the pet, which invalidates the old code (old printed code stops working). The user must print and swap the physical code. (only the admin can do that)
4. **Duplicate meal log within the grace window.** Second log attempt for an already-logged slot shows the warning banner (2.7) rather than silently creating a second entry.
5. **Editing schedule after logs already exist.** Changing a meal slot's time/amount only affects future occurrences; past Meal History entries retain the amount/time that was actually logged.
6. **Multiple unresolved meals stacking up.** If the app hasn't been opened in a while, several meal slots may be unresolved at once — Catch-Up Prompt resolves them one at a time, oldest first, rather than presenting a bulk form.
7. **Bag change mid-history.** Food inventory calculations should be scoped to the currently active bag; starting a new bag doesn't retroactively change past consumption history, just resets the "remaining" counter.
8. **Vaccine/medical entries with no due date.** Vaccines given as one-time/no-repeat should support leaving "next due date" blank without triggering false alerts.
