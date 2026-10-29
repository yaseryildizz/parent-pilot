# UX Flows

## First launch and authentication

Explain the product's use of sensitive school content before requesting access. The user authenticates, receives actionable recovery errors, and can access privacy/deletion information. Authentication method is **TBD**.

## Add child

Collect only the minimum child, school, class, and timezone context needed for applicability. Allow multiple children/schools. Make optional fields explicit and editable; do not infer identity from documents without confirmation.

## PDF upload → processing → review

1. User chooses a PDF. The app copies the security-scoped import into temporary app-controlled storage, closes external access, and validates the copy.
2. The selected filename and size are shown. Scope remains `unknown` and no child/school/class IDs are sent until real context exists.
3. User explicitly confirms upload; selection alone never uploads content.
4. App uploads through `DocumentService`, then checks bounded processing status with cancellation and phase-specific retry.
5. On completion, the extraction result remains in feature state for the future review screen.
6. Future review groups candidates with source excerpts, confidence, applicability, conflicts, and proposed effects. High-impact/uncertain changes cannot be silently applied.

Temporary imports are removed when replaced or reset and are not permanent document persistence. Extraction Review remains unimplemented.

After completion, the user explicitly opens Extraction Review. Candidates show semantic confidence, attention status, and expandable source evidence. Safe bulk acceptance excludes explicit-review items. All candidates must be resolved before confirmation. Confirmation retains an in-memory review result only—Calendar persistence remains future work.

The Documents flow uses parent-friendly “Analyze document” language, clearly separates selection from analysis, and gives calm uploading, analysis, success, and recovery states without fake progress. Review uses custom cards and a persistent confirmation summary so decisions and remaining work stay visible.

## Smart calendar and reminders

Calendar entries distinguish recurring rules, one-off events, and exceptions. Selecting an item shows provenance and change history. Reminder creation/editing shows local time and linked event; changes remain recoverable and explainable.

## Errors and recovery

Preserve uploaded/processed state across retries; never ask for duplicate actions when the server may have succeeded. Give safe guidance for unsupported, malicious, unreadable, expired-auth, offline, and partial-processing states. Do not expose raw provider errors.

## Future email ingestion

The user explicitly connects or forwards a school mailbox/source (**approach TBD**), sees the granted scope, selects relevant senders where feasible, and can disconnect. Messages follow the same processing and review lifecycle as PDFs. Email is MVP scope, but this UX follows PDF foundation work.

Future WhatsApp sharing, images, sites, portals, and APIs require separate flows and consent.
