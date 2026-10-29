# ParentPilot

ParentPilot is an AI-powered iOS companion that turns fragmented school communication into trusted, actionable information for parents. It is designed to preserve the original source, identify conflicts and one-off schedule changes, and support a smart school calendar and reminders.

## Status

The repository contains a **local PDF upload and extraction-review vertical slice**. The SwiftUI app uploads PDFs to a Fastify backend, polls processing status, and presents extracted information for review. The backend supports deterministic fake extraction and a text-based PDF/OpenAI pipeline.

Calendar mapping and an in-memory calendar store are tested service components. Review confirmation currently closes the review sheet; it is **not yet connected to calendar storage**. This is development infrastructure, not a production-ready service.

## Repository structure

- `ParentPilot/`: existing iOS application target
- `ParentPilotTests/`: unit-test target
- `ParentPilotUITests/`: UI-test target
- `backend/`: TypeScript/Fastify document API, PDF processing, and backend tests
- `docs/product/`: scope, rules, roadmap, and user flows
- `docs/engineering/`: iOS architecture and engineering practices
- `docs/backend/`: proposed service, API, database, and sync boundaries
- `docs/ai/`: extraction pipeline, trust, prompts, and evaluation
- `docs/design/`: design-system foundations, accessibility, and localization
- `docs/security/`: security, privacy, retention, and threats
- `docs/operations/`: environments, delivery, telemetry, and analytics
- `docs/DECISIONS.md`: lightweight architectural decision records

Start with [PRODUCT.md](docs/product/PRODUCT.md), [PRODUCT_RULES.md](docs/product/PRODUCT_RULES.md), and [ARCHITECTURE.md](docs/engineering/ARCHITECTURE.md). Open decisions are tracked in [DECISIONS.md](docs/DECISIONS.md).

## Technology direction

- iOS: SwiftUI + MVVM, Swift Concurrency, and Observation (`@Observable`) where appropriate
- Structure: feature-oriented Views and ViewModels calling services; optional use cases for complex/reusable business logic; repositories only for meaningful data-source complexity; DTO/domain separation throughout
- Backend: Fastify + TypeScript with backend-owned AI processing; Supabase is **Proposed**, not selected
- MVP inputs: PDF upload and school email ingestion

## Local development

Start the backend in deterministic development mode:

```sh
cd backend
npm ci
npm run build
HOST=127.0.0.1 DOCUMENT_PROCESSOR=fake npm start
```

Open `ParentPilot.xcodeproj`, choose the `ParentPilot` scheme and an iOS simulator, and run the Debug configuration. The app defaults to `http://127.0.0.1:8080`. Choose a synthetic PDF, tap **Analyze document**, and open **Review 3 items**. Fake mode returns fixed sample candidates regardless of PDF text; it does not validate live AI quality. High-impact/conflicting changes require an individual decision before confirmation.

See [backend/README.md](backend/README.md) for the real text-based PDF processor configuration. Keep provider credentials on the backend.

## Verification

```sh
cd backend
npm run typecheck
npm test
npm audit
```

Run `ParentPilotTests` from Xcode for the iOS unit suite. See [TESTING.md](docs/engineering/TESTING.md) for test boundaries and [LOCAL_VALIDATION.md](docs/engineering/LOCAL_VALIDATION.md) for the latest local verification and known gaps.

## Not implemented

Authentication, durable storage, calendar UI, the review-to-calendar connection, notification scheduling, email ingestion, and production hosting are not implemented. No school portal scraping, share extension, screenshot ingestion, or OCR is included.

See [CONTRIBUTING.md](CONTRIBUTING.md) before implementation work.
