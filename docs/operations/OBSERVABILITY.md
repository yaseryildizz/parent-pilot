# Observability

Observe the user journey without observing private content. Correlate mobile request IDs with API, upload, job, extraction, persistence, and notification stages.

- **Metrics:** request/error/latency, upload outcomes, queue depth/age, stage failures, retry counts, time-to-review, reminder delivery, and deletion workflow completion.
- **Logs:** structured stable codes, environment/version, request/job/source opaque IDs, timings, and redacted failure context.
- **Traces:** sampled across API and asynchronous jobs with content-free attributes.
- **Alerts:** sustained availability, isolation/security signals, queue backlog, provider failure, processing regression, and deletion/export failures.

Never log document/email bodies, extracted text, child names, auth tokens, signed URLs, prompts containing content, or raw provider responses. Restrict and audit telemetry access with bounded retention.

Vendors, SLOs, sampling, retention, on-call ownership, dashboards, and alert thresholds are **TBD**.
