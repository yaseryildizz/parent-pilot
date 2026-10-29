# Navigation

Use `NavigationStack` with typed feature routes. An app-level router owns transitions between authentication/onboarding and signed-in flows; each feature owns only navigation state inside its boundary. Route values carry stable domain identifiers, not DTOs or large models. This is a lightweight navigation model, not a Coordinator architecture.

- Push for hierarchical exploration and durable destinations (calendar → event → source).
- Use sheets for focused creation, review, filters, or short decisions that preserve the underlying context.
- Avoid nested coordinators until independent feature flows require them.

Deep links are parsed into a validated intent, then resolved after authentication and data access checks. Unknown, deleted, unauthorized, or stale targets show a safe recovery state.

Notification taps route through the same intent resolver. They must not reveal sensitive content on a locked device and must not assume the referenced item still exists. Cold-start intents wait for session restoration; duplicate deliveries must not produce duplicate screens.

URL scheme/universal-link format and tab structure are **TBD**.

The first concrete transition uses direct sheet composition from a completed Documents result to Extraction Review. This keeps the large result out of `AppRoute`, requires explicit user action, and adds no fake Calendar destination.
