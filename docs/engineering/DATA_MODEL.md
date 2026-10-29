# Conceptual Data Model

This is a domain vocabulary, not a finalized database schema.

- **User:** authenticated account and preferences; owns/accesses household data.
- **Child:** privacy-sensitive child profile associated with one or more schools/classes over time.
- **School:** institution, authoritative domains/senders, and IANA timezone.
- **SchoolClass:** class/year/group membership with validity dates; supports applicability.
- **Source:** origin/channel and trust metadata (email, document, manual, future channels).
- **SourceDocument:** immutable ingested artifact metadata, storage reference, hash, processing status, and retention state. Raw content is access-controlled separately.
- **Announcement:** informational communication that may contain zero or more actionable candidates.
- **SchoolEvent:** dated/all-day/recurring calendar concept with applicability, status, and provenance.
- **Task:** actionable obligation with optional due date and assignee context.
- **Reminder:** delivery rule tied to an event/task or explicit manual intent.
- **Extraction:** versioned processing attempt, model/pipeline metadata, status, and aggregate confidence.
- **ExtractionCandidate:** validated proposed fact/action, evidence span, confidence, applicability, and review decision.
- **ScheduleOverride:** dated replacement/cancellation of occurrences without rewriting the recurrence rule.

## Implemented document-ingestion vocabulary

The iOS foundation now defines `SchoolDocument`, `DocumentSource`, `DocumentScope`, `DocumentProcessingStatus`, `ExtractionResult`, `ExtractionCandidate`, `ExtractionCandidateType`, `SourceEvidence`, and `ExtractionConfidence`. A document carries optional school/child/class context without transport fields. Material candidates require non-empty evidence tied to a source document. Confidence is a normalized value type; automation policy remains separate.

`DocumentProcessingStatus` represents lifecycle only: uploaded, queued, processing, completed, or failed. `ExtractionOrigin` separately records whether a completed result was newly processed or reused. `SelectedDocument` is feature-local temporary picker state and is not a backend/domain `SchoolDocument`.

Extraction candidates now carry explicit conflict and schedule-override flags. Review decisions and the confirmed review result remain feature-local until a real Calendar/Reminder consumer justifies promotion.

Document scope is one of school-wide, year-group, class-group, child-specific, private-parent, or unknown. It describes privacy/applicability context, not permission to reuse data. The backend remains authoritative for deduplication and authorization.

## Relationships and invariants

A source document can have multiple versioned extractions; an extraction yields candidates; accepted candidates create or amend domain items while retaining links to all evidence. A domain item may have multiple supporting or conflicting sources. Overrides reference the affected recurring event and occurrence/date. Membership and access are account-scoped on every server query.

`DocumentID` is an opaque client value; transport DTOs map explicitly into these domain models. Identifiers, cardinalities, household sharing, deletion mechanics, recurrence representation, history/versioning, and storage schema remain **TBD**. See [DATABASE.md](../backend/DATABASE.md).

Calendar-domain models preserve date-only values separately from local date/time plus optional source timezone. Weekly recurrence supports weekdays, bounds, and cancelled/changed/replaced exceptions. `SchoolTask` avoids collision with Swift Concurrency `Task`. Overrides allow an unknown prior time, and provenance links every output to its extraction evidence.

## Local calendar storage identities

`SchoolEventID`, `TaskID`, `ReminderIntentID`, and `ScheduleOverrideID` are stable value types used by `CalendarStore`. Reviewed extraction mapping derives their raw values from the extraction-candidate identity, so mapping and saving the same review repeatedly addresses the same logical records rather than creating duplicates.

The current store uses upsert semantics: an unknown ID inserts, the same ID and value is a no-op in effect, and the same ID with a changed value replaces that stored value. Two unequal values with the same identity inside one mapping result are invalid because their intended update order is ambiguous. Skipped candidates are mapping diagnostics and are not persisted as actionable calendar data.
