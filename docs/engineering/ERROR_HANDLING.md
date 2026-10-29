# Error Handling

Errors cross boundaries as typed, app-meaningful failures: unauthenticated, forbidden, validation, unavailable/offline, rate-limited, conflict, unsupported document, processing failed, and unknown. Services—or repositories where one is justified—map transport/provider errors; raw payloads and sensitive content never reach ViewModels, Views, or logs.

UI errors state what happened, what remains safe, and the next action. Preserve user input and server job identifiers. Retry only transient/idempotent operations with bounded backoff and jitter; honor server retry guidance. Do not retry authentication, policy, validation, or malicious-file failures automatically.

Upload/creation calls require idempotency keys so timeout recovery cannot duplicate events. Partial failures expose per-item status and never claim full success. Cancellation is neutral. Programmer invariants may assert in development but production must fail safely.

Telemetry includes a request ID, stable error code, operation, and redacted context—never document/email bodies or child names. Escalation and support flows are **TBD**.

The Documents feature translates validation, upload, processing-timeout/failure, and extraction-unavailable errors into actionable presentation errors. Failed state retains only the retry context needed for the failed phase. Cancellation is represented separately from failure and must not trigger automatic retry.

Calendar conversion is partial-success: an incomplete or unsupported accepted candidate produces a typed skipped entry without failing valid siblings. Malformed accepted/rejected overlap is skipped safely.

Calendar persistence exposes implementation-independent `CalendarStoreError` values only for actionable contract failures. An empty stable identity is invalid, and unequal values sharing one identity inside a single atomic save produce `duplicateIdentityConflict`. The in-memory store validates the complete mapping result before committing, so failure leaves its prior snapshot unchanged. A same-ID value in a later successful save is an intentional upsert, not a conflict.
