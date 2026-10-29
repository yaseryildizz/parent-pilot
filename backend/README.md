# ParentPilot Backend

Fastify backend for the iOS PDF upload vertical slice.

This implementation supports two document processors:

- `DOCUMENT_PROCESSOR=fake` for deterministic local/testing extraction.
- `DOCUMENT_PROCESSOR=openai` for text-based PDF extraction, OpenAI Responses API structured extraction, deterministic validation, and the existing iOS extraction DTO response.

It intentionally does not add Supabase, authentication, durable persistence, queues, OCR, email ingestion, subscriptions, school portal integrations, or deployment infrastructure.

## Run Locally

```sh
npm install
npm run build
npm start
```

Defaults:

- `HOST=0.0.0.0`
- `PORT=8080`
- `MAX_UPLOAD_BYTES=10485760`
- `FAKE_PROCESSING_DELAY=250`
- `DOCUMENT_PROCESSOR=fake`
- `OPENAI_MODEL=gpt-5-mini`
- `OPENAI_API_KEY=`

Binding to `0.0.0.0` makes the server reachable from an iPhone on the same LAN during development. Do not treat this as a production deployment configuration.

## API

- `GET /health`
- `POST /v1/documents` with multipart PDF field `file`, iOS metadata fields, and response matching `DocumentUploadResponseDTO`
- `GET /v1/documents/:id/status` matching `DocumentProcessingStatusDTO`
- `GET /v1/documents/:id/extraction` matching `ExtractionResultDTO`

Set `DOCUMENT_PROCESSOR=openai` and provide `OPENAI_API_KEY` to run the real text-based PDF pipeline. The model is configurable through `OPENAI_MODEL`; `gpt-5-mini` is a proposed development default and can be changed without touching route code.

Both processors move uploaded documents through:

```text
queued -> processing -> completed
```

The OpenAI processor keeps provider calls backend-owned. It stores uploaded PDF bytes in memory only for this local development implementation, extracts page-aware text with `pdfjs-dist`, normalizes text deterministically, calls `/v1/responses` with JSON Schema Structured Outputs and no tools, validates evidence against source pages, drops invalid candidates, and returns only DTO-compatible candidates.

## Tests

```sh
npm run typecheck
npm test
npm audit
```

Tests use Fastify injection and a manual scheduler so lifecycle assertions do not rely on real sleeps. OpenAI tests use stub transports/clients and never call the live API.
