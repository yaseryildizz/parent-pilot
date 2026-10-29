# Swift Code Style

This document is the single source of truth for formatting and organizing Swift source in ParentPilot. It complements, but does not repeat, the application boundaries in [ARCHITECTURE.md](ARCHITECTURE.md).

## Principles

- Prefer clarity over cleverness and explicit names over abbreviations.
- Keep types and functions small enough to express one coherent responsibility.
- Prefer value types and immutable `let` bindings when their semantics fit.
- Use the narrowest reasonable access level. A symbol is internal only when another file in the module intentionally uses it.
- Avoid force unwraps, force casts, implicitly unwrapped optionals, nested ternaries, magic numbers, and deeply nested control flow.
- Do not add generic base classes or abstractions solely for uniformity.

## Formatting

- Indent with four spaces; never tabs.
- Aim for 100–120 characters per line where practical. Preserve a longer line when wrapping would make it less readable.
- Put one declaration or statement on a line.
- Use one blank line between logical sections and avoid vertical padding without meaning.
- For a non-trivial multiline call, place each argument on its own line and put the closing parenthesis on a new line.
- Use trailing commas in multiline collections and argument lists when they make future diffs cleaner.
- Use type inference when the type is obvious and spell out types when inference obscures intent.
- Omit unnecessary `self.` except where required to disambiguate initialization, capture semantics, or shadowed names.

## Naming

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Names should read clearly at the call site.

- Name dependencies by role: `documentService`, `processingMonitor`, and `apiClient`.
- Name methods by intent: `selectDocument(at:)`, `analyzeSelectedDocument()`, `retryProcessing()`, and `fetchExtractionResult(for:)`.
- Use boolean names that read as assertions, such as `hasPendingReview` and `isProcessing`.
- Capability protocols use role names such as `DocumentService`, `APIClient`, and `DocumentImporting`; do not append `Protocol` or add an `I` prefix.
- Concrete implementations describe their mechanism, such as `RemoteDocumentService`, `URLSessionAPIClient`, and `TemporaryDocumentImporter`.
- Test doubles use `Fake`, `Stub`, or `Spy` according to their actual behavior.
- Avoid vague names such as `data`, `obj`, `manager`, `helper`, and `util` unless the surrounding API gives the term a precise meaning.

## Type organization

For classes, structs, actors, and observable ViewModels, prefer this order:

1. Nested types
2. Dependencies
3. Public or internal state
4. Private state
5. Initialization
6. Public API
7. Internal helpers
8. Private helpers

Use `// MARK:` sections when they materially improve navigation in a substantial type. Do not add sections to tiny types.

For SwiftUI views, prefer:

1. Dependencies and input
2. `@State` and other local state
3. `body`
4. Computed subviews
5. Actions and presentation helpers

## Access control

- Keep implementation details `private`.
- Use `private(set)` when callers may observe state but mutation belongs to the declaring type.
- Do not expose mutable collections when a read-only view is sufficient.
- Do not declare symbols `public` unless a real module boundary requires it.
- File-scoped test fixtures and test doubles should normally be `private`.

## Initializers and dependencies

Use explicit initializer injection for dependencies. Keep non-trivial dependency parameters on separate lines:

```swift
init(
    documentService: DocumentService,
    validator: DocumentValidator,
    processingMonitor: DocumentProcessingMonitoring
) {
    self.documentService = documentService
    self.validator = validator
    self.processingMonitor = processingMonitor
}
```

ViewModels must not hide production dependencies in default arguments. Defaults are acceptable for inert value configuration when the call site remains unambiguous.

## Functions and control flow

- Give each function one clear purpose, but do not mechanically fragment readable code into trivial helpers.
- Prefer `guard` for invalid state and early failure paths.
- Prefer exhaustive `switch` statements for ParentPilot-owned enums. Avoid `default` so new cases receive compiler feedback.
- Use modern optional binding such as `guard let document else { return }` where supported.
- Do not test optionals with `!= nil` when binding communicates the intent.
- Use trailing closures when they improve the call site.

## SwiftUI

- Keep `body` declarative and extract meaningful sections such as `header`, `content`, and `actionButtons` when it becomes difficult to scan.
- Keep business and workflow logic out of view closures. Buttons should invoke clearly named ViewModel methods.
- Do not create a separate file for every small visual fragment; extract a type when it has a reusable or coherent visual responsibility.
- Order modifiers consistently where practical: content/layout, frame, padding, background, shape or clipping, overlay, and accessibility.
- Treat accessibility modifiers as part of the component contract, not optional decoration.

## ViewModels and state

- UI-facing ViewModels are `@MainActor`, use `@Observable` where appropriate, and are `final` unless subclassing is required.
- Presentation state is read-only externally when possible.
- Dependencies and task handles are private.
- ViewModels do not construct raw networking requests, expose SwiftUI view types, or use a global dependency lookup.
- Prefer intent-based methods over event-shaped names such as `handleButton()` or vague operations such as `process()`.
- Model mutually exclusive UI states with enums and associated values instead of parallel booleans and optionals that permit invalid combinations.

## Errors

- Prefer typed domain- or service-specific errors over strings and `NSError`.
- Error values describe failure semantics and do not contain user-interface copy.
- Do not leak raw backend details through domain errors.
- Keep conversion from technical errors to presentation messages at the presentation boundary.

## DTO and domain mapping

Transport types end in `DTO`; domain types never do. ParentPilot uses the dedicated `DocumentDTOMapper` convention for the document API because mapping spans related DTOs, validates cross-field requirements, and normalizes server values. Service boundaries call this mapper before returning domain models.

Keep mapping explicit and searchable. Do not introduce per-DTO `toDomain()` methods alongside `DocumentDTOMapper` unless a future boundary deliberately adopts and documents a different convention.

## Concurrency

- Use Swift Concurrency for asynchronous work.
- Isolate UI-facing mutable state to `MainActor`.
- Add `Sendable` where it reflects real value or boundary semantics.
- Preserve structured cancellation and call `Task.checkCancellation()` at meaningful long-running boundaries.
- Avoid `Task.detached`, unsafe shared mutable state, and casually suppressed concurrency diagnostics.
- Do not add `@unchecked Sendable` unless framework constraints make it unavoidable; document the synchronization or immutability that makes the conformance safe.

## Comments

- Comments explain why a choice exists, not what an obvious line does.
- Use `///` for APIs and non-obvious domain abstractions that genuinely benefit from documentation.
- Do not document every internal symbol or retain stale comments.
- A necessary `TODO` must state the condition under which it can be resolved.

## Tests

- Test names describe observable behavior, not implementation details.
- Organize each test as arrange, act, assert, without literal section comments unless a complex test benefits from them.
- Prefer one behavior per test and deterministic fakes or stubs.
- Do not sleep to coordinate tests. Use controllable async boundaries or polling helpers with explicit deadlines.
- Name doubles accurately: a fake implements useful behavior, a stub returns configured results, and a spy records interactions.

## Future automated enforcement

Automated enforcement is **TBD**. SwiftLint and SwiftFormat may be evaluated after these conventions stabilize. Until that decision is recorded, neither tool is a project dependency or required build step. Xcode's bundled formatting support may be used locally as an editing aid, but this document remains authoritative.
