# ParentPilot

ParentPilot is an AI-powered iOS companion that turns fragmented school communication into trusted, actionable information for parents. It is designed to preserve the original source, identify conflicts and one-off schedule changes, and support a smart school calendar and reminders.

## Status

The repository is in the **foundation** phase. The existing Xcode project contains the initial SwiftUI app and test targets; product features, backend services, data storage, and third-party dependencies are intentionally not implemented yet.

## Repository structure

- `ParentPilot/`: existing iOS application target
- `ParentPilotTests/`: unit-test target
- `ParentPilotUITests/`: UI-test target
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
- Backend: backend-owned AI processing; Supabase is **Proposed**, not selected
- MVP inputs: PDF upload and school email ingestion

## Not implemented

No ingestion, AI, authentication, storage, calendar, reminder, or email functionality has been built. No school portal scraping, share extension, screenshot ingestion, or third-party dependency is included.

See [CONTRIBUTING.md](CONTRIBUTING.md) before implementation work.
