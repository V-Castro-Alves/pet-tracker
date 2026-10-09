# Pet Care module

Pet Care is an optional first-party HouseMate module for coordinating a household's shared pet responsibilities. It retains the useful parts of the original Pet Tracker product—fast feeding confirmation, food inventory, health records, photos, and printable QR entry—without acting as a separate application.

This document is subordinate to [HOUSEHOLD_SPEC.md](HOUSEHOLD_SPEC.md). The household specification defines the shared task model and module boundary; [API.md](API.md) and [`public/openapi.json`](../public/openapi.json) define the public integration contract.

## Product goals

- Make routine pet care visible to everyone in the household so it is neither missed nor accidentally repeated.
- Make feeding confirmation quick, including from a printable pet-specific QR code.
- Warn the household before food runs out.
- Keep simple, user-maintained weight, vaccination, and medical history with the pet.

Pet Care does not provide veterinary integration, structured clinical records, product or barcode lookup, a native mobile application, or a third-party plugin runtime.

## Module and access boundary

- A household administrator enables or disables Pet Care for one household. Disabling it hides Pet Care and prevents new module activity without deleting pets, records, tasks, or history.
- Every pet belongs to exactly one household. Current household membership is the only source of pet access; pets have no separate users, roles, or invitations.
- Household members may view pets and manage collaborative care. Household administrators control module state and destructive shared actions such as deleting a pet or regenerating its QR code.
- Pet Care appears within the selected household. It is not a global pet area.
- Pet URLs use opaque public IDs. The QR token identifies a pet but is not authorization; a signed-in user must still have current access to the pet's household.

## Pet profiles and records

A pet profile stores its name, species, optional breed, birthdate, sex, notes, time zone, and photo. Photos preserve the full image in bounded frames.

The profile provides access to:

- shared Pet Care tasks and their occurrence history;
- feeding history and the active food bag;
- dated weight entries and a simple trend view;
- vaccine records with optional next-due dates and clinic notes;
- chronological freeform medical entries; and
- a printable or downloadable pet-specific QR code.

Health records are household-maintained reference notes, not medical advice or records synchronized with a veterinarian. A vaccine without a next-due date must not produce a false due alert.

## Care tasks and scheduling

Pet Care uses HouseMate's one scheduling engine. A Pet Care task is a normal household `Task` with one `PetCareTaskDetail` that selects a pet, a care type, and—only for feeding—an optional default amount in grams.

Supported care types are feeding, medication, walking, grooming, vaccination, and custom. Tasks may be one-off, daily, or scheduled on selected weekdays. Multiple care times are represented by multiple tasks.

Occurrences are persisted. Assignment or title changes retain occurrence identity, and schedule edits replace only future pending occurrences. Any household member may resolve a collaborative occurrence; the record keeps both the acting user and the credited member. Skipped and completed occurrences remain in history.

There are no Pet Care-specific meal slots, pet reminder preferences, or second occurrence generator. Members configure their own reminder timing and weekday overrides through the shared task reminder controls.

## Feeding workflow

A scheduled feeding is completed through its task occurrence. Completion records the actual amount, time, actor, credited member, and linked feeding entry. The task resolution, feeding entry, food deduction, durable event, and notifications are committed together so partial feeding state is not exposed.

If a pet is fed outside a scheduled occurrence, a member records an explicit additional feeding. It creates feeding history and deducts inventory but does not silently resolve a scheduled task.

Completing the same occurrence twice must be rejected rather than creating duplicate feeding or inventory deductions. Pending and overdue feeding tasks remain visible through the shared Today and task views; Pet Care does not maintain a separate missed-meal queue.

## QR feeding entry

Each pet has a regenerable QR token. The printable code opens `/feeding/:qr_token` and offers an appropriate pending feeding occurrence for confirmation.

- An unauthenticated visitor signs in before continuing and returns to the protected destination.
- The server rechecks current household membership and that Pet Care is enabled before showing or accepting the action.
- A user without access receives an access-denied response; possession of the token never grants household access.
- Regenerating the token invalidates old printed codes, so the household must replace them.

## Food inventory

A member starts a food bag with its total weight and low-stock threshold. Only one bag may be active for a pet. Each recorded feeding atomically subtracts its actual amount from that bag, while completed bags retain their own history.

The UI shows remaining weight, low-stock state, bag history, and an estimated number of days remaining based on recent feeding consumption. Crossing the threshold emits one idempotent low-stock notification for that bag rather than notifying after every later feeding.

## Notifications and time zones

Pet Care uses HouseMate's shared in-app and optional Web Push delivery. Notifications use stable per-user deduplication keys so recurring jobs can run safely. Failed delivery to one browser subscription must not prevent attempts to the user's other devices.

Task scheduling follows the task's named time zone. Pet feeding history and pet-local dates use the pet's time zone, while the Today dashboard groups and displays work using the viewer's time zone. Tests and background jobs must pass explicit dates and zones around day boundaries.
