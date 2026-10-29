# Performance

Measure before optimizing. User-critical budgets should cover launch, calendar rendering, review-list interaction, upload progress responsiveness, memory, energy, network bytes, and processing-status latency; numeric budgets are **TBD** after baseline profiling.

- Keep parsing, hashing, file IO, and network work off the main actor.
- Paginate/calendar-window server reads and render long collections lazily.
- Cache only data with a clear invalidation and privacy policy; avoid caching raw documents unnecessarily.
- Stream uploads where possible, compress only when it preserves evidence, and support cancellation/resume when the backend permits.
- Poll processing with bounded backoff or use a server push mechanism (**TBD**); stop when backgrounded or terminal.
- Profile on representative older supported devices and poor networks.

Performance telemetry must use aggregate timings and identifiers, not sensitive content. Correctness, provenance, and accessibility take precedence over marginal speed.
