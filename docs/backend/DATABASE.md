# Database Direction

PostgreSQL through Supabase is **Proposed**. The final model follows the concepts in [DATA_MODEL.md](../engineering/DATA_MODEL.md), but this document does not finalize tables.

## Required properties

- Account/household isolation enforced server-side and, where available, with row-level policies
- Immutable source identity and evidence references; versioned extractions and decisions
- Auditable links from derived items to supporting/conflicting sources
- Idempotency uniqueness scoped to actor and operation
- Recurrence exceptions and overrides without destructive history rewrites
- UTC instants plus IANA timezone/source-local representations
- Soft workflow states distinct from retention-driven deletion
- Transactional acceptance of candidates and resulting calendar/reminder changes

Indexes should follow measured access patterns: account plus time window, processing status, source hash/identifier, and applicability. Avoid exposing sequential identifiers. Encrypt in transit and at rest; consider field-level measures after threat review.

**TBD:** household model, schema, migration tool, backup/restore objectives, regions, search strategy, audit retention, and whether raw extracted text is stored.
