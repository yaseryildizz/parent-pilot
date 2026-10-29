# Release Process

## Release readiness

- Scope and product rules are accepted; migrations/contracts are compatible.
- Tests, AI evaluation, security/privacy, accessibility, localization, and performance gates pass.
- Telemetry, alerts, support/recovery, deletion/export, and rollback are verified in staging.
- App privacy disclosures, release notes, and store metadata reflect actual behavior.

Use staged rollout where available and monitor errors, job latency/failure, extraction quality, notification delivery, and correction/conflict signals. Define explicit halt/rollback owners. Server behavior remains compatible with supported app versions; remote kill switches may disable risky ingestion/automation without hiding existing user data.

Versioning scheme, release owner, TestFlight cohorts, rollout percentages, support window, incident severity policy, and go/no-go thresholds are **TBD**. Never rush AI policy/model changes without versioned evaluation and rollback.
