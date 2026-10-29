# API Contract Conventions

These are conventions, not final endpoints.

- Version externally visible contracts (for example, a major path or negotiated schema); additive changes remain backward compatible.
- Authenticate every private request and authorize every object by account membership. Never trust client-supplied ownership.
- Accept/return a request ID; log it with redacted metadata and expose it in safe errors.
- Use a stable error envelope: machine code, user-safe message, request ID, optional field issues, and retry guidance.
- Encode instants as RFC 3339 UTC plus relevant IANA timezone; encode all-day values as ISO calendar dates. Retain source-local text separately as evidence.
- Require scoped idempotency keys for uploads, submissions, decisions, and other retryable mutations.

## Document ingestion lifecycle

The initial client contract is **Proposed** as:

1. `POST /v1/documents` accepts `multipart/form-data` with a PDF `file`, declared `scope`, and optional `schoolID`, `childID`, and `classID`.
2. The response returns the document identity, source, scope/context, upload time, and initial processing status.
3. `GET /v1/documents/{documentID}/status` returns `uploaded`, `queued`, `processing`, `completed`, or `failed`.
4. `GET /v1/documents/{documentID}/extraction` returns the schema version, extraction origin (`newlyProcessed` or `reused`), and provenance-bearing candidates when available.

The server verifies file type, size, content, authorization, and any client-supplied metadata. Final limits, upload-intent/direct-transfer design, and endpoint payloads are **TBD**. Bounded polling is the initial iOS MVP implementation and remains replaceable by push or another mechanism without changing domain lifecycle states.

The backend recalculates an original-bytes SHA-256 hash and, after safe extraction, a normalized-content hash. A client hash may later be accepted only as an optimization hint. Authoritative deduplication and reuse policy remain server-owned; see [AI_PIPELINE.md](../ai/AI_PIPELINE.md#deduplication-and-privacy-safe-reuse).

### Initial local implementation

The development backend in `backend/` implements the current iOS DTO contract enough for the local upload-to-review flow:

- `POST /v1/documents` accepts multipart field `file` with `application/pdf`, plus `scope`, `schoolID`, `childID`, and `classID` fields sent by `RemoteDocumentService`.
- Upload responses match `DocumentUploadResponseDTO`: `id`, `originalFilename`, `uploadedAt`, `source`, `scope`, `processingStatus`, `schoolID`, `childID`, and `classID`.
- Status responses match `DocumentProcessingStatusDTO`: `documentID` and `status`.
- Extraction responses match `ExtractionResultDTO`: `documentID`, `schemaVersion`, `generatedAt`, `origin`, and `candidates`.

The local backend uses the stable iOS raw values for source (`pdfUpload`), statuses (`queued`, `processing`, `completed`, `failed`), origin (`newlyProcessed`), candidate types, document scopes, temporal values, and source evidence.

Errors use the existing envelope convention:

```json
{
  "error": {
    "code": "missing_pdf",
    "message": "A PDF file is required.",
    "requestID": "request-id",
    "retryable": false,
    "fieldIssues": []
  }
}
```

Implemented local error codes include `invalid_multipart_request`, `missing_pdf`, `invalid_filename`, `unsupported_media_type`, `payload_too_large`, `invalid_scope`, `unknown_document`, `extraction_not_ready`, `processing_failed`, and `internal_error`.

The real local processor may also return safe extraction error codes such as `invalid_pdf`, `no_extractable_text`, `ocr_required`, `pdf_extraction_failed`, `ai_provider_unavailable`, `ai_rate_limited`, `ai_invalid_response`, and `semantic_validation_failed`. These remain transport errors; the existing status endpoint still returns only the DTO-safe processing status.

## Asynchronous processing

Submission returns a stable job/extraction identifier and status. States are **Proposed:** queued, processing, needs_review, completed, failed, cancelled. Clients can fetch status; event/push mechanism is **TBD**. Retrying must not duplicate domain items.

Transport DTOs are versioned at the boundary and explicitly mapped to domain models by `DocumentService`. ViewModels never receive DTOs. Provider names, prompt text/versions, database rows, and raw AI output are not exposed to mobile. Pagination, concurrency tokens, finalized endpoint shapes, and compatibility window are **TBD**.
