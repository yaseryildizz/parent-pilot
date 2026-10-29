# Threat Model

## Assets and boundaries

Protect accounts/tokens, child-school relationships, documents/email, extracted evidence, calendar/reminders, AI/provider secrets, and audit data. Trust boundaries exist at the iOS app/API, identity provider, storage, job runner, AI provider, email provider, notification service, and operator access.

## Principal threats and controls

| Threat | Primary controls |
|---|---|
| Cross-account object/file access | Server authorization, row/object isolation, unguessable IDs, negative tests |
| Account/session takeover | Vetted auth, secure token storage, rotation/revocation, rate limits, **MFA TBD** |
| Malicious PDF/email or parser exploit | Type/size checks, scanning, sandboxing, patched parsers, resource limits |
| Prompt injection/data exfiltration | Untrusted-content delimiting, no AI side effects, minimized context, schema/rule validation |
| Hallucinated or harmful schedule change | Evidence requirements, conflict detection, impact/confidence policy, user confirmation |
| Secret/provider exposure | Backend-only secrets, scoped credentials, secret scanning/rotation |
| Notification/privacy leakage | Minimal push payloads, protected local display, user controls |
| Replay/duplicate mutation | TLS, idempotency, timestamps/versions, bounded signed upload intents |
| Insider/log/analytics leakage | Least privilege, redaction, audit, retention, production access process |
| Deletion failure | Cascading deletion workflow, tombstones, backup expiry verification |

Abuse cases include forged official-looking sources, compromised school senders, zip/PDF bombs, tracking links, ambiguous relative dates, and child misclassification. Residual risk, DDoS controls, supply-chain posture, and formal review cadence are **TBD**.
