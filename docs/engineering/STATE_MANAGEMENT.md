# State Management

In ParentPilot's SwiftUI + MVVM architecture, each feature ViewModel normally owns its presentation state and coordinates user actions. Views remain declarative: they render ViewModel state, hold only genuinely view-local state, and forward intent without embedding business workflows.

## Ownership

- Keep ephemeral UI details such as focus, disclosure, animation, or transient selection in the owning View.
- Keep loading state, displayed app models, validation feedback, recoverable errors, and action coordination in the feature ViewModel.
- Keep durable server data authoritative in services/repositories and the backend; do not copy the same mutable model into app, feature, and view state.
- Keep feature-specific state inside the feature. Promote state only when multiple features genuinely share it, with an explicit owner and lifecycle.
- Do not use global mutable singleton state. App-wide session or routing state belongs to a deliberately scoped app-level owner.

Use Swift Observation and `@Observable` for ViewModels where the supported OS/toolchain and behavior make it appropriate. UI-updating ViewModels and their state mutations run on `@MainActor`. Do not add Combine merely to implement observation or asynchronous work; introduce it only for a concrete requirement Swift Concurrency and Observation do not satisfy.

## Lifecycle state

Represent mutually exclusive states explicitly, such as `idle`, `loading`, `loaded(value)`, `empty`, and `error(recovery)`. Avoid independent booleans that can contradict one another. Keep previously useful content visible during refresh when appropriate, and derive display values instead of storing duplicated state.

Optimistic updates are allowed only when the operation has a clear rollback and server reconciliation strategy. A ViewModel may coordinate the operation, but raw networking, file storage, authentication SDK calls, calendar APIs, and notification APIs belong in services.

## Concurrency and cancellation

Swift Concurrency is the default. Network, parsing, hashing, and persistence work must not block the main actor. Structured tasks belong to the View or ViewModel lifecycle that initiated them. Cancel obsolete loads, searches, and processing-status observations when replaced or torn down; check cancellation before publishing results. Cancellation is not a user-facing failure.

ViewModels should avoid detached, unowned tasks and implicit long-lived observation. Services define async operations and cancellation behavior; ViewModels translate results into presentation state.

## Navigation

Keep navigation state separate from ViewModels where practical. A router or feature navigation owner manages routes, sheets, deep links, and notification destinations. A ViewModel can emit a user-action result or navigation intent without directly owning the navigation stack.

**TBD:** local persistence technology and offline depth. See [ARCHITECTURE.md](ARCHITECTURE.md), [NAVIGATION.md](NAVIGATION.md), and [SYNC_STRATEGY.md](../backend/SYNC_STRATEGY.md).

## Documents feature

`DocumentsViewModel` uses one mutually exclusive state enum: idle, selected, uploading, processing, completed, or failed with retry context. The selected temporary document survives upload/processing failures so retry does not require another pick. An operation identity prevents cancelled or replaced work from publishing stale state. Explicit cancellation returns upload to selected state or retains remote processing/extraction context for retry; reset cancels work and removes the temporary copy.

Extraction Review wraps immutable domain candidates with one decision enum and disclosure state; it never mutates extracted facts. Summary and confirmation eligibility are derived, and the confirmed result remains in memory for future navigation.
