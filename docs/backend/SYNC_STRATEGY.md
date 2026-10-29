# Sync Strategy

The backend is authoritative for documents, extraction decisions, calendar items, and reminders. The app may cache a privacy-minimized read model for responsive launch and poor connectivity; local persistence technology is **TBD**.

- Sync by stable IDs, server versions, updated timestamps/cursors, and tombstones where deletion must propagate.
- Use conditional writes or versions to detect concurrent edits; do not silently use last-write-wins for reviewed facts.
- Queue only safe, idempotent client mutations. Preserve idempotency keys until terminal reconciliation.
- Processing jobs continue server-side after app termination; the app resumes by identifier.
- Refresh on foreground, relevant notification/deep link, user action, and bounded background opportunities.
- Scope caches and cursors per account; purge on sign-out and deletion.

Offline creation/edit policy, conflict UI, cache encryption, background refresh, server push versus polling, and retention of tombstones are **TBD**. MVP may use online-required mutations while permitting cached reads, if communicated clearly.

## Current local foundation

`CalendarStore` now defines the local calendar persistence contract, and `InMemoryCalendarStore` provides a temporary non-durable implementation. It is not a synchronization source and does not change backend authority. Stable domain IDs and idempotent upserts establish the caller contract a future durable and synchronized adapter must preserve.

Saving a `CalendarMappingResult` is atomic from the caller's perspective. Future SwiftData or backend-aware implementations should use one transaction where practical and must not expose partially committed mapping output as success. Server versions, merge policy, tombstones, and cross-device conflict resolution remain **TBD**.
