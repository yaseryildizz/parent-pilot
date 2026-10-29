# Environments and Configuration

Use isolated development, staging, and production environments with separate projects/accounts, databases, storage, OAuth/email credentials, AI keys, push credentials, and telemetry destinations. Production data must never be copied into lower environments.

Configuration is injected at build/deploy time and validated on startup. The iOS app may contain non-secret environment endpoints/identifiers; all provider and service secrets stay in managed backend secret storage. Local `.env` files are ignored and documented through safe example keys only.

Use synthetic/de-identified fixtures in development and automated tests. Restrict production access with least privilege, audited break-glass procedures, and credential rotation. Backend platform, region/residency, environment naming, secret manager, developer bootstrap, and feature-flag service are **TBD**.

## Local backend development

The development backend reads safe local configuration from environment variables:

- `HOST`, default `0.0.0.0`
- `PORT`, default `8080`
- `MAX_UPLOAD_BYTES`, default `10485760`
- `FAKE_PROCESSING_DELAY`, default `250` milliseconds per fake lifecycle transition
- `DOCUMENT_PROCESSOR`, default `fake`; set to `openai` for the real text-based PDF pipeline
- `OPENAI_MODEL`, default `gpt-5-mini` as a proposed development default
- `OPENAI_API_KEY`, required only when `DOCUMENT_PROCESSOR=openai`

Use `backend/.env.example` as the documented template. Local `.env` files must not contain secrets and must remain uncommitted.

`OPENAI_API_KEY` is backend-only. It must never be exposed to iOS, checked into source control, logged, or copied into client configuration.

For the iOS simulator, the Debug app defaults to `http://127.0.0.1:8080`.

For a physical iPhone, `localhost` and `127.0.0.1` refer to the phone, not the developer Mac. Start the backend with `HOST=0.0.0.0`, find the Mac's LAN address, and set the Debug launch environment variable:

```sh
PARENTPILOT_API_BASE_URL=http://192.168.x.x:8080
```

Do not hardcode a developer LAN IP into the project. The app target permits local HTTP networking only in Debug so local LAN testing can reach the development backend. Release configuration must continue using HTTPS production endpoints.
