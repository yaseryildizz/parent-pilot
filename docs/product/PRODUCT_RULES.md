# Product Rules

These rules govern domain behavior. Thresholds and exact automation policy are **Proposed** until validated.

## Events and reminders

- Create an event only from user input or a validated candidate with source provenance.
- Preserve source, extraction, confidence, applicability, and decision history.
- A reminder must reference its event/task when derived from one; never create duplicates merely because processing retried.
- Reminder changes follow the same confirmation policy as the underlying event change.

## Schedule overrides and recurrence

- A message limited to a date/date range creates an exception or `ScheduleOverride`; it does not mutate the recurring schedule.
- An exception records the original occurrence and replacement/cancellation.
- A permanent schedule change requires explicit evidence and must preserve prior history.
- Ambiguous relative dates (for example, “this Thursday”) require the source timestamp, school timezone, and validation; unresolved ambiguity requires review.

## Conflicts, changes, and trust

- Never silently overwrite conflicting facts. Link competing assertions and show the proposed resolution.
- Higher-trust sources are preferred, but recency, specificity, applicability, and explicit correction language also matter. Trust alone does not erase conflict.
- High-impact or uncertain changes require confirmation. **TBD:** define impact levels and confidence thresholds.
- Automatic action is allowed only for validated, non-conflicting, sufficiently confident, policy-approved candidates; initial MVP default is **Proposed: review first**.
- Confidence is advisory, not truth. **Proposed:** ordinary candidates at or above 0.85 may start accepted; pickup changes, payments, holidays, generic events, conflicts, and schedule overrides always require an explicit decision. “Accept safe items” excludes those items, and confirmation requires every candidate to be resolved.

## Duplicate detection

Use stable source identifiers/content hashes plus normalized child, type, date/time, and subject signals. Merge/link only when identity is sufficiently established; otherwise present possible duplicates. Retries use idempotency keys.

The backend, not iOS, makes authoritative document deduplication decisions. Exact or normalized-content hash equality may reduce repeated processing, but never permits cross-household reuse on its own. Scope, authorization, and the privacy-safe reuse rules in [AI_PIPELINE.md](../ai/AI_PIPELINE.md#deduplication-and-privacy-safe-reuse) apply before any reuse.

## Applicability

Every derived item identifies applicable child, school, class, or an unresolved scope. Never apply a class-specific item to all children by assumption. Cross-child matches require independent evidence.

## Timezones

Store instants as UTC where meaningful and retain the originating school timezone and local representation. All-day dates remain calendar dates, not midnight instants. School-local timezone governs interpretation unless the source explicitly says otherwise. Daylight-saving transitions require explicit timezone identifiers; ambiguous/nonexistent local times require review.

See [SOURCE_TRUST.md](../ai/SOURCE_TRUST.md) and [DATA_MODEL.md](../engineering/DATA_MODEL.md).

## Reviewed extraction conversion

Only accepted candidates enter deterministic calendar-domain mapping. Incomplete accepted candidates are reported as skipped, never guessed or discarded. Generated items retain candidate evidence. Reminder intents express proposed behavior only; they are not notifications. Schedule overrides never invent a previous value.

Actionable mapped items save by stable domain identity. Repeating the same confirmed review must not create duplicates; a later value for the same identity updates the local record. One confirmed mapping result is committed atomically, while skipped candidates remain diagnostics rather than calendar entries. The current in-memory store is non-durable and does not imply that calendar UI, EventKit export, or notification scheduling has occurred.
