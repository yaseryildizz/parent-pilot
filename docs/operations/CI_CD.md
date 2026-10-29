# CI/CD

CI should produce reproducible, reviewable artifacts and block promotion on material failures.

## Proposed pipeline

1. Validate formatting, documentation links, secrets, licenses, and static analysis.
2. Build iOS targets and run deterministic unit/feature tests.
3. Run backend contract/integration, database isolation, migration, and security checks when backend exists.
4. Run a focused UI/accessibility suite and AI regression evaluation at appropriate gates.
5. Sign/promote immutable artifacts through staging to production with protected credentials and approvals.

Deploy database changes with forward/backward-compatible migrations and tested rollback/roll-forward plans. Pin actions/toolchains, minimize CI permissions, and retain artifacts/logs without sensitive content.

CI provider, branch policy, supported Xcode/iOS matrix, signing automation, deployment platform, approval gates, and AI metric thresholds are **TBD**.
