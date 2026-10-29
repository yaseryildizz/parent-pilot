# Contributing

## Current boundary

This phase establishes documentation only. Do not add product features, placeholder screens, dependencies, or backend infrastructure without an approved scope change. Preserve Xcode signing and bundle identifiers.

## Working agreements

1. Read the relevant product rule and ADR before changing behavior.
2. Keep MVP and future work explicit; label unresolved choices **Proposed** or **TBD**.
3. Preserve provenance across every layer. Do not allow AI output to bypass validation or confirmation rules.
4. Keep DTOs at data-source/repository boundaries and expose domain models inward.
5. Prefer the smallest useful abstraction. Add use cases and protocols when they isolate policy, side effects, or test boundaries—not for simple view-local behavior.
6. Never commit secrets, real child data, school documents, or production email content.

## Change quality

- Follow [CODE_STYLE.md](docs/engineering/CODE_STYLE.md) for Swift formatting, naming, and source organization.
- Add tests in proportion to risk; see [TESTING.md](docs/engineering/TESTING.md).
- Include accessibility and localization considerations in UI changes.
- Update documentation and ADRs when contracts or decisions change.
- Avoid logging sensitive content; follow [PRIVACY.md](docs/security/PRIVACY.md).
- Keep commits focused and explain user-visible behavior and recovery paths in reviews.

## Definition of done

A change has clear acceptance criteria, handles loading/empty/error states, is cancellable where appropriate, preserves source and request identifiers, passes relevant tests, and updates affected documentation. Security- or privacy-sensitive changes require explicit review.
