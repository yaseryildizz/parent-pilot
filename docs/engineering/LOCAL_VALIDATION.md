# Local validation — 2026-10-30

Scope: verify the existing local PDF upload and extraction-review slice before building calendar UI or durable storage. All document inputs were synthetic repository fixtures. No live OpenAI request was made.

## Results

- Backend `npm run typecheck`: passed.
- Backend `npm test`: all 18 tests passed, including real PDF text extraction, stubbed AI processing, validation, and lifecycle endpoints.
- iOS `ParentPilotTests`: all 41 tests passed (45 executions including parameterized cases) on the iPhone 18 Pro / iOS 27.0 simulator. No runtime warnings were reported in the result bundle.
- Local HTTP smoke check: health, multipart PDF upload, status polling to `completed`, and extraction retrieval succeeded with `DOCUMENT_PROCESSOR=fake`.
- Cross-language smoke check: compiled the existing Swift `RemoteDocumentService`, API client, DTO mappers, processing monitor, and extraction-review model into a temporary macOS executable. Against the running backend, the synthetic PDF uploaded successfully and yielded three domain candidates with evidence. Safe bulk acceptance left the conflicting pickup change unresolved; explicitly rejecting it enabled confirmation with two accepted candidates and one rejected candidate. This exercised real HTTP with the existing app components, independently of SwiftUI.
- Dependency audit initially reported two moderate package findings. Updated the lockfile within existing manifest ranges: Fastify 5.12.3 → 5.12.7 and fast-uri 3.1.7 → 3.1.9 / 4.1.4 → 4.2.3. Backend typecheck and all 18 tests passed again; `npm audit fix` reported zero remaining vulnerabilities.

## UI verification limits

The Debug app built, installed, and launched on the iPhone Duo / iOS 27.1 simulator. The initial document screen and native PDF picker were observed. The picker showed no recent files; the simulator's Files app storage container could not be resolved, and the Device Hub window then became unavailable to UI automation. Selecting a PDF and reaching the review sheet through the UI were **not verified**. The HTTP/Swift-component smoke checks above do not replace this remaining UI check.

## Confirmed gaps

- `ExtractionReviewView.confirmReview()` obtains a review result and dismisses the sheet. It does not call `ReviewedCalendarCommitService` or save to `CalendarStore`.
- `AppDependencies` creates an `InMemoryCalendarStore`, but no calendar screen presents its data.
- Both document storage on the backend and calendar storage on iOS are in memory; data does not survive process restarts.
- Fake processing returns fixed sample content, so this run makes no claim about live AI extraction quality. Automated real-pipeline tests use stubbed AI responses.
- The existing UI tests are launch/performance templates; there is no automated PDF-picker-to-review regression test yet.

Next implementation slice: connect review confirmation to the existing calendar commit service, present accepted events/tasks in a calendar or agenda screen, and cover successful saves, failed saves, and repeated confirmation. Durable storage and notifications remain subsequent work.
