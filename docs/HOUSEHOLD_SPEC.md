# HouseMate

HouseMate coordinates shared household tasks and optional first-party modules. Rails/Hotwire pages and API-backed interactions share the same domain services. Users can belong to multiple households; administrators manage membership, modules, settings, and integrations while all members manage responsibilities.

Tasks have one embedded schedule: one-off, daily, or selected weekdays at a named-zone local time. Multiple times use multiple tasks. Persisted occurrences retain completion actors and credited household members. Assigned responsibilities may be completed by another member. The Today dashboard groups overdue/today/upcoming work by the viewer's zone, filters by household or personal assignment, and displays recent activity.

Pet Care is a first-party module enabled independently for each household by an administrator. It is not a dynamically loaded third-party plugin system. Enabling it adds household-scoped pets and pet-care task details; it never creates a separate membership or scheduling system. Pet profiles inherit household access and retain health, photo, QR, feeding, and inventory features. Feeding uses task occurrences and typed feeding entries. An additional feeding is an explicit separate entry. Disabling Pet Care prevents new module activity and hides module UI/API resources without deleting stored records or task history; re-enabling restores them.

The retained Pet Care product behavior and module-specific invariants are documented in [PET_CARE.md](PET_CARE.md).

Every task is a household responsibility. Standard tasks use only shared task fields. A Pet Care task has one associated details record containing its pet, care type, and optional feeding amount. Pet-only fields do not live on the core task table. Pet Care initially supports feeding, medication, walking, grooming, vaccination, and custom care types.

The primary navigation is Today, Tasks, Household, and Notifications. Pet Care appears inside the selected household, never as a global Pets destination. Household administration separates members, modules, integrations, and settings. The Today dashboard remains the primary operational view and groups overdue, current, upcoming, and recently resolved work in the viewer's time zone.

The public API, authentication, events, retry semantics, and example integration are documented in API.md and public/openapi.json. External plugins run outside the application. OAuth, voice adapters, automatic rotation, monthly recurrence, custom fields, and offline writes are deferred.

HouseMate starts from a clean pre-production database baseline. Standalone pets, pet memberships, pet invitations, meal slots, legacy meal logs, and the old reminder engine are not part of the product and are not migrated. Every pet belongs to exactly one household and authorization always derives from current household membership.
