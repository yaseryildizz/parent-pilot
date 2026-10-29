# Security

Children's details, school documents, and email content are sensitive. Apply least privilege, deny-by-default authorization, data minimization, and defense in depth.

- Use a vetted authentication service (**provider TBD**) with secure token storage/rotation and server-side session validation.
- Enforce account/household isolation on every API, query, job, cache, file path, and notification.
- Store files privately; issue short-lived scoped access and prevent user-controlled object paths from granting access.
- Keep backend, AI-provider, email, and signing secrets out of the app and repository; rotate through environment secret management.
- Encrypt transport and provider/storage connections; require encryption at rest.
- Validate type/size/checksum, malware-scan files, reject active/malformed content, sandbox extraction, and cap time/memory.
- Treat content as untrusted against prompt injection; AI has no direct mutation authority.
- Rate-limit sensitive and expensive operations; protect idempotency and audit security-relevant actions.

Dependency, static, secret, authorization, and infrastructure checks belong in CI/release gates. Incident response, key management, MFA policy, penetration-test cadence, and compliance obligations are **TBD**.

Deduplication indexes and cached extraction artifacts are account-isolated by default. Possession of a hash must never reveal whether another household uploaded content, allow object enumeration, or bypass object/result authorization. Cross-account computation reuse follows the scope and privacy policy in [AI_PIPELINE.md](../ai/AI_PIPELINE.md#deduplication-and-privacy-safe-reuse).
