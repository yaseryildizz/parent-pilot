# Decisions

Lightweight ADRs record current direction. **Accepted** decisions require an explicit superseding entry to change; **Proposed** decisions remain open.

## ADR-001 — Backend-owned AI processing

- **Status:** Accepted
- **Context:** School content is sensitive and AI output needs centralized validation, observability, and secret protection.
- **Decision:** Provider calls and AI pipeline execution occur on the backend; mobile contains no AI-provider secrets.
- **Consequences:** Requires asynchronous lifecycle/recovery and backend operation; enables provider abstraction and consistent policy.

## ADR-002 — SwiftUI + MVVM as the primary iOS architecture

- **Status:** Accepted
- **Context:** ParentPilot needs clear presentation-state ownership and testable external boundaries without forcing every user action through a ceremonial Clean Architecture chain.
- **Decision:** SwiftUI + MVVM is the primary iOS architecture. Each user-facing feature normally has a declarative View and a `@MainActor` ViewModel. ViewModels coordinate presentation state and call services; they do not perform raw networking. Use cases and repositories are tools, not mandatory layers. Add a use case only for complex, reusable, multi-service business logic or logic needing focused tests. Add a repository only for meaningful persistence or data-source complexity.
- **Consequences:** The default flow is View → ViewModel → Service/Repository → API client or local persistence. Features remain cohesive and easy to navigate. Protocol injection is used where substitution has value. Navigation stays outside ViewModels where practical. The team avoids pass-through layers and generic base ViewModel/repository/service inheritance.

## ADR-003 — DTO/domain separation

- **Status:** Accepted
- **Decision:** API, database, and provider DTOs are mapped at data/repository boundaries and do not enter UI/domain APIs.
- **Consequences:** Contract changes require mapping but do not contaminate product rules.

## ADR-004 — Mandatory source provenance

- **Status:** Accepted
- **Decision:** Every AI-derived material fact/action retains source identity and evidence through review and persistence.
- **Consequences:** Data/API/UI models must support multiple supporting and conflicting sources.

## ADR-005 — Structured validation of AI output

- **Status:** Accepted
- **Decision:** AI output must satisfy a versioned schema and deterministic semantic/policy validation before persistence or action.
- **Consequences:** Invalid/ambiguous results abstain or route to review; model confidence alone is insufficient.

## ADR-006 — Supabase backend services

- **Status:** Proposed
- **Decision:** Evaluate Supabase for authentication, PostgreSQL, and private file storage.
- **Consequences:** No implementation commitment yet. Validate isolation, region, retention, jobs, email integration, operations, and cost before acceptance.

## ADR-007 — No school portal scraping in MVP

- **Status:** Accepted
- **Decision:** Do not scrape school portals in MVP.
- **Consequences:** Avoids fragile/unauthorized access; future portals require official or explicitly authorized integrations.

## ADR-008 — PDF and email as MVP sources

- **Status:** Accepted
- **Decision:** MVP ingestion sources are PDF upload and school email; share extension, images, websites, portals, and APIs are later scope.
- **Consequences:** Foundation must support source extensibility without implementing speculative connectors.

## ADR-009 — Backend-owned document deduplication

- **Status:** Accepted
- **Decision:** The backend calculates/verifies original-byte and normalized-content hashes and makes all authoritative deduplication decisions. A future client hash is only an optimization hint.
- **Consequences:** iOS does not determine document identity or security from hashes. Exact duplicate detection can avoid repeated work while remaining server-verifiable.

## ADR-010 — Hashes do not authorize cross-account reuse

- **Status:** Accepted
- **Decision:** File/content hash equality alone never permits cross-account extraction reuse. Reuse requires compatible scope, authorization, and privacy policy; private and child-specific content remains account-isolated by default.
- **Consequences:** When safe reuse cannot be proven, the backend processes inside the requesting account boundary. Hash lookups must not leak another account's activity or source records.

## ADR-011 — Versioned extraction cache identity

- **Status:** Accepted
- **Decision:** Backend extraction cache identity includes content hash, extraction schema version, prompt version, and extraction engine/model version.
- **Consequences:** Pipeline changes do not silently reuse stale results. Mobile receives schema compatibility information but no provider or prompt internals. Storage implementation remains **TBD**.

## ADR-012 — DocumentService returns domain models

- **Status:** Accepted
- **Decision:** `DocumentService` exposes document domain models and domain-relevant errors; explicit mappers keep transport DTOs inside networking/service boundaries.
- **Consequences:** Future ViewModels remain independent of API payloads. The remote service depends directly on `APIClient`; no repository or use case is introduced without additional complexity.

## ADR-013 — Temporary copy for imported PDFs

- **Status:** Accepted
- **Decision:** Copy a selected security-scoped PDF into app-controlled temporary storage before asynchronous upload, then promptly stop external resource access.
- **Consequences:** Upload and retry do not depend on a picker URL remaining accessible. Copies are removed when replaced or reset and are not permanent persistence.

## ADR-014 — Replaceable bounded polling for document processing

- **Status:** Accepted
- **Decision:** The initial iOS MVP checks processing status through an injected, bounded `DocumentProcessingMonitor` using Swift concurrency.
- **Consequences:** Polling has proposed interval/attempt limits, supports cancellation, and is isolated from the ViewModel so push can replace it later.

## ADR-015 — Separate processing lifecycle from extraction origin

- **Status:** Accepted
- **Decision:** `DocumentProcessingStatus` describes only uploaded/queued/processing/completed/failed lifecycle. `ExtractionOrigin` describes newly processed versus reused results.
- **Consequences:** UI and monitoring have unambiguous terminal states while deduplication provenance remains available on the result.

## ADR-016 — Review confirmation requires complete decisions

- **Status:** Accepted
- **Decision:** Every extracted candidate must be accepted or rejected before confirmation. Safe bulk acceptance excludes high-impact, conflict, and override candidates.
- **Consequences:** Confirmation is deliberately conservative; its result remains in memory and does not write Calendar data.

## ADR-017 — Present review directly from Documents

- **Status:** Accepted
- **Decision:** Present the real Extraction Review as a sheet composed from the completed result rather than carrying that result in `AppRoute`.
- **Consequences:** Navigation remains lightweight and explicit; a durable identifier-based route can be introduced when persistence exists.

## ADR-018 — Deterministic partial-success calendar mapping

- **Status:** Accepted
- **Decision:** Convert only accepted extraction candidates through a pure mapper with deterministic candidate-derived IDs, explicit temporal structure, lightweight provenance, and typed skipped reasons.
- **Consequences:** One incomplete candidate does not block valid outputs. Reminder intents schedule nothing, previous override values are never invented, and EventKit/persistence remain future work.

## ADR-019 — CalendarStore persistence boundary; SwiftData deferred

- **Status:** Accepted
- **Context:** Reviewed calendar output needs deterministic local save/query behavior now, while the durable storage technology, synchronization model, and migration requirements are not yet settled.
- **Decision:** Calendar persistence is abstracted behind `CalendarStore`; SwiftData is deferred. The contract accepts and returns persistence-framework-independent domain models, uses stable typed identities and idempotent upserts, and saves each `CalendarMappingResult` atomically. `InMemoryCalendarStore` is the temporary non-durable actor implementation. `ReviewedCalendarCommitService` owns review mapping plus atomic persistence without UI, EventKit, or notification responsibilities.
- **Consequences:** Callers do not depend on SwiftData/Core Data entities, repeated commits do not duplicate records, and a future adapter must preserve ordering, atomicity, and identity semantics through an explicit Domain ↔ Persistence Entities ↔ SwiftData mapping boundary. Recurring definitions are stored and returned without fabricated occurrence expansion.

## ADR-020 — Fastify TypeScript backend foundation

- **Status:** Accepted
- **Context:** The iOS upload/review flow needs a real local HTTP backend before Supabase, authentication, and durable infrastructure are selected.
- **Decision:** Use a small Node.js, TypeScript, and Fastify backend under `backend/` for the document lifecycle API. Keep dependencies minimal, build routes through an app factory, and map responses to the existing iOS DTO contract. Support an explicit processor switch between deterministic fake extraction and the first real text-based PDF/OpenAI extraction pipeline.
- **Consequences:** The app can validate real multipart upload, polling, and extraction retrieval against local HTTP endpoints. Current `InMemoryDocumentStore` and in-memory file retention are explicitly temporary development infrastructure and must be replaced before production. OpenAI stays backend-owned behind a focused extraction client with JSON Schema Structured Outputs, deterministic validation, hashes, and internal processing metadata. OCR, Supabase, auth, email ingestion, subscriptions, analytics, and deployment infrastructure remain out of scope.

## Open questions

- **TBD:** authentication/backend/provider choices, regions, household/access model, and compliance obligations.
- **TBD:** email connection/forwarding approach, sender verification, scopes, and disconnect behavior.
- **TBD:** AI provider/model, OCR, supported languages, confidence/impact thresholds, and automatic-action eligibility.
- **TBD:** upload limits, malware scanning, job runner, notification scheduling, and the eventual successor to initial iOS polling.
- **TBD:** final database schema, durable local technology and migrations, recurrence occurrence expansion, offline depth, synchronization conflicts, and deletion cascades.
- **TBD:** retention/deletion/export SLAs, provider data handling, backup expiry, and analytics/observability vendors.
- **TBD:** brand tokens, app locales, navigation/tab and deep-link formats, supported OS/device matrix, and accessibility audit cadence.
- **TBD:** success/release/SLO/performance targets, CI/CD stack, signing/release ownership, and support/incident processes.
