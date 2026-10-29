# Privacy

Collect only information required to associate school communications with the right child and action. Explain collection, purpose, AI processing, retention, and sharing before connecting email or uploading content.

- Child profiles, documents, extracted text, email content, and provenance are privacy-sensitive.
- Limit email access to the narrowest feasible scope; connection model is **TBD**. Disconnecting stops new ingestion.
- Send providers only necessary content under configured no-training/retention terms where available; provider/region are **TBD**.
- Do not include sensitive content in analytics, crash reports, logs, push payloads, or lock-screen text by default.
- Users must be able to view sources, correct derived data, export their data, and request deletion. Exact export format and SLA are **TBD**.
- Separate consent/notice from product terms and make privacy controls discoverable.

Household sharing, child consent/age obligations, lawful basis, residency, subprocessors, and regulatory applicability require legal/privacy review and are **TBD**. See [DATA_RETENTION.md](DATA_RETENTION.md).

## Extraction reuse

File or content hash equality is never consent, authorization, or proof that content is public. Cross-account reuse is denied by default for child-specific or private-parent material and permitted for broader official content only under verified scope and policy. The canonical reuse rules are in [AI_PIPELINE.md](../ai/AI_PIPELINE.md#deduplication-and-privacy-safe-reuse).
