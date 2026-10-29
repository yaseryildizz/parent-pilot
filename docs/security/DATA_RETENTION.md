# Data Retention

No durations are finalized. Before production, define and publish a purpose-bound schedule by data class.

| Data class | Proposed handling | Retention |
|---|---|---|
| Upload/email raw content | Private, minimized, deletable | TBD |
| Extracted text/evidence | Store only if needed for explainability/reprocessing | TBD |
| Domain items/provenance | Retain while account needs history | TBD |
| Extraction/model metadata | Minimize; avoid raw prompts where possible | TBD |
| Security/audit logs | Redacted, access-limited, tamper-resistant | TBD |
| Analytics/diagnostics | Aggregated or pseudonymous; no content | TBD |
| Backups/tombstones | Encrypted and expiry-bound | TBD |

Deletion must cover primary storage, search/cache, pending jobs, files, derived items according to documented cascade semantics, and eventual backup expiry. Legal/security holds must be exceptional, authorized, and transparent where permitted. Export precedes deletion when requested and authorized.

Define deletion SLA, backup expiry, account-versus-item deletion, email disconnect behavior, provenance cascade/anonymization, and provider deletion guarantees before launch.
