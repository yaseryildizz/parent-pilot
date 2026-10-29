# Testing Strategy

- **Domain/unit:** product rules, timezone/date parsing boundaries, recurrence exceptions, trust/conflict policy, duplicate signals, DTO mapping, and error mapping.
- **ViewModel:** presentation-state transitions, cancellation, retry, stale-response rejection, and user/navigation intents using service fakes. Use repository fakes only in features that genuinely have a repository boundary.
- **Contract/integration:** API schema compatibility, authentication/isolation, upload lifecycle, idempotency, and database policies.
- **UI:** a small set of critical flows—authentication recovery, upload/review, override confirmation, calendar provenance, and accessibility.
- **AI evaluation:** versioned, de-identified/synthetic corpus and metrics in [AI_EVALUATION.md](../ai/AI_EVALUATION.md); AI snapshots are not substitutes for semantic assertions.

Use deterministic clocks, UUIDs, timezones, and schedulers. Include daylight-saving, locale, duplicate retry, multi-child, conflicting-source, malicious-content, and denied-access cases. Never use production child or email data in tests.

CI must run fast deterministic tests on changes; broader integration, UI, security, and evaluation suites can run at gated stages. Coverage is diagnostic, not a target by itself. Required devices/OS versions and numeric gates are **TBD**.

Documents ViewModel tests use injected service, importer, and processing-monitor doubles. Polling tests control status delivery without real sleeps and cover selection, explicit upload, state transitions, extraction retention, phase-specific retries, cancellation, and stale-work replacement. SwiftUI rendering details remain outside unit-test scope.

Calendar-mapping tests cover accepted/rejected filtering, deterministic identifiers, date-only/local-time preservation, recurrence/exceptions, provenance, partial success, override safety, and reminder-intent sufficiency without EventKit.

Calendar-storage contract tests cover insert/fetch, repeated idempotent saves, same-ID updates, typed identities, deterministic ordering, inclusive date-range queries, task/reminder/override storage, deletion, clearing, atomic rejection of conflicting batches, and concurrent actor-isolated saves. Commit-service tests cover review mapping plus persistence and repeated commits. These tests use the in-memory implementation and no sleeps, files, databases, EventKit, or notification APIs.

Backend tests live in `backend/tests` and use Node's built-in test runner plus Fastify injection. Document lifecycle tests use an injected manual scheduler so queued, processing, completed, and failed transitions are deterministic and do not rely on real sleeps.

Real-processing tests use synthetic PDF fixtures under `backend/tests/fixtures`. The PDF extractor is exercised against text-based and no-text PDFs. OpenAI client tests use stubbed `fetch` transports and assert the request includes JSON Schema Structured Outputs, untrusted-document prompt boundaries, usage capture, and provider failure mapping. Integration-style processing tests use the real PDF extractor with a stub `AIExtractionClient`; automated tests must not call the live OpenAI API or require an API key.

Run backend checks with:

```sh
cd backend
npm run typecheck
npm test
npm audit
```
