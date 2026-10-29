import Foundation
import Testing

@testable import ParentPilot

@Suite(.serialized)
@MainActor
struct DocumentsViewModelTests {
    @Test
    func startsIdle() throws {
        let harness = try makeHarness()
        #expect(harness.viewModel.state == .idle)
    }

    @Test
    func selectingPDFStoresTemporarySelectionWithoutUploading() async throws {
        let harness = try makeHarness()

        harness.viewModel.selectDocument(at: URL(fileURLWithPath: "/picked/newsletter.pdf"))
        try await waitUntil { harness.viewModel.state.selectedDocument != nil }

        guard case .selected(let document) = harness.viewModel.state else {
            Issue.record("Expected selected state")
            return
        }
        #expect(document.displayFilename == "newsletter.pdf")
        #expect(await harness.service.uploadCallCount == 0)
    }

    @Test
    func validationFailureKeepsActionableSelectionState() async throws {
        let harness = try makeHarness(importError: .unsupportedDocument)

        harness.viewModel.selectDocument(at: URL(fileURLWithPath: "/picked/image.png"))
        try await waitUntil {
            if case .failed = harness.viewModel.state { return true }
            return false
        }

        #expect(harness.viewModel.state == .failed(nil, .unsupportedDocument, .chooseAnother))
    }

    @Test
    func analysisTransitionsThroughProcessingAndStoresExtraction() async throws {
        let monitor = TestProcessingMonitor(statuses: [.processing, .completed], pausesAfterFirst: true)
        let harness = try makeHarness(monitor: monitor)
        try await selectPDF(using: harness.viewModel)

        harness.viewModel.analyzeSelectedDocument()
        #expect(isUploading(harness.viewModel.state))
        try await waitUntil { isProcessing(harness.viewModel.state, status: .processing) }

        await monitor.resume()
        try await waitUntil { isCompleted(harness.viewModel.state) }

        guard case .completed(_, _, let extraction) = harness.viewModel.state else {
            Issue.record("Expected completed state")
            return
        }
        #expect(extraction.candidates.count == 1)
        #expect(extraction.origin == .newlyProcessed)
    }

    @Test
    func uploadFailureRetainsDocumentAndSupportsRetry() async throws {
        let service = TestDocumentService(
            uploadResults: [.failure(.uploadFailed), .success(makeRemoteDocument(status: .completed))],
            extractionResults: [.success(try makeExtractionResult())]
        )
        let harness = try makeHarness(service: service)
        try await selectPDF(using: harness.viewModel)

        harness.viewModel.analyzeSelectedDocument()
        try await waitUntil { isFailed(harness.viewModel.state, error: .uploadFailed) }
        #expect(harness.viewModel.state.selectedDocument != nil)

        harness.viewModel.retryProcessing()
        try await waitUntil { isCompleted(harness.viewModel.state) }
        #expect(await service.uploadCallCount == 2)
    }

    @Test
    func processingFailureRetainsRemoteRetryContext() async throws {
        let monitor = TestProcessingMonitor(statuses: [.processing, .failed])
        let harness = try makeHarness(monitor: monitor)
        try await selectPDF(using: harness.viewModel)

        harness.viewModel.analyzeSelectedDocument()
        try await waitUntil { isFailed(harness.viewModel.state, error: .processingFailed) }

        guard case .failed(let document?, _, .processing(let remoteDocument)) = harness.viewModel.state else {
            Issue.record("Expected processing retry context")
            return
        }
        #expect(document.displayFilename == "newsletter.pdf")
        #expect(remoteDocument.id == DocumentID(rawValue: "document-1"))
    }

    @Test
    func extractionFailureCanRetryWithoutUploadingAgain() async throws {
        let service = TestDocumentService(
            uploadResults: [.success(makeRemoteDocument(status: .completed))],
            extractionResults: [.failure(.extractionUnavailable), .success(try makeExtractionResult())]
        )
        let harness = try makeHarness(service: service)
        try await selectPDF(using: harness.viewModel)

        harness.viewModel.analyzeSelectedDocument()
        try await waitUntil { isFailed(harness.viewModel.state, error: .extractionUnavailable) }
        harness.viewModel.retryProcessing()
        try await waitUntil { isCompleted(harness.viewModel.state) }

        #expect(await service.uploadCallCount == 1)
        #expect(await service.extractionCallCount == 2)
    }

    @Test
    func cancellingUploadReturnsToSelectedState() async throws {
        let service = TestDocumentService(suspendUploads: true)
        let harness = try makeHarness(service: service)
        try await selectPDF(using: harness.viewModel)

        harness.viewModel.analyzeSelectedDocument()
        #expect(isUploading(harness.viewModel.state))
        harness.viewModel.cancelProcessing()

        guard case .selected = harness.viewModel.state else {
            Issue.record("Expected selected state after cancellation")
            return
        }
    }

    @Test
    func selectingNewFileCancelsWorkAndReplacesSelection() async throws {
        let service = TestDocumentService(suspendUploads: true)
        let harness = try makeHarness(service: service)
        try await selectPDF(using: harness.viewModel)
        harness.viewModel.analyzeSelectedDocument()

        harness.viewModel.selectDocument(at: URL(fileURLWithPath: "/picked/replacement.pdf"))
        try await waitUntil { harness.viewModel.state.selectedDocument?.displayFilename == "replacement.pdf" }

        guard case .selected(let document) = harness.viewModel.state else {
            Issue.record("Expected replacement selection")
            return
        }
        #expect(document.displayFilename == "replacement.pdf")
    }

    private func selectPDF(using viewModel: DocumentsViewModel) async throws {
        viewModel.selectDocument(at: URL(fileURLWithPath: "/picked/newsletter.pdf"))
        try await waitUntil {
            if case .selected = viewModel.state { return true }
            return false
        }
    }

    private func makeHarness(
        service: TestDocumentService? = nil,
        monitor: TestProcessingMonitor? = nil,
        importError: DocumentServiceError? = nil
    ) throws -> DocumentsHarness {
        let selectedService: TestDocumentService
        if let service {
            selectedService = service
        } else {
            selectedService = TestDocumentService(
                uploadResults: [.success(makeRemoteDocument(status: .queued))],
                extractionResults: [.success(try makeExtractionResult())]
            )
        }
        let monitor = monitor ?? TestProcessingMonitor(statuses: [.completed])
        let importer = TestDocumentImporter(error: importError)
        return DocumentsHarness(
            viewModel: DocumentsViewModel(
                documentService: selectedService,
                documentValidator: DocumentValidator(maximumUploadBytes: nil),
                documentImporter: importer,
                processingMonitor: monitor
            ),
            service: selectedService
        )
    }
}

@MainActor
private struct DocumentsHarness {
    let viewModel: DocumentsViewModel
    let service: TestDocumentService
}

private actor TestDocumentImporter: DocumentImporting {
    private let error: DocumentServiceError?

    init(error: DocumentServiceError? = nil) { self.error = error }

    func importPDF(from sourceURL: URL, validator: DocumentValidator) throws -> SelectedDocument {
        if let error { throw error }
        return SelectedDocument(
            id: UUID(),
            temporaryURL: sourceURL,
            displayFilename: sourceURL.lastPathComponent,
            fileSize: 1_024,
            mimeType: "application/pdf"
        )
    }

    func removeTemporaryDocument(_ document: SelectedDocument) {}
}

private actor TestDocumentService: DocumentService {
    private var uploadResults: [Result<SchoolDocument, DocumentServiceError>]
    private var extractionResults: [Result<ExtractionResult, DocumentServiceError>]
    private let suspendUploads: Bool
    private(set) var uploadCallCount = 0
    private(set) var extractionCallCount = 0

    init(
        uploadResults: [Result<SchoolDocument, DocumentServiceError>] = [],
        extractionResults: [Result<ExtractionResult, DocumentServiceError>] = [],
        suspendUploads: Bool = false
    ) {
        self.uploadResults = uploadResults
        self.extractionResults = extractionResults
        self.suspendUploads = suspendUploads
    }

    func uploadDocument(at fileURL: URL, metadata: DocumentUploadMetadata) async throws -> SchoolDocument {
        uploadCallCount += 1
        if suspendUploads { try await Task.sleep(for: .seconds(60)) }
        guard !uploadResults.isEmpty else { throw DocumentServiceError.uploadFailed }
        return try uploadResults.removeFirst().get()
    }

    func fetchProcessingStatus(documentID: DocumentID) async throws -> DocumentProcessingStatus { .completed }

    func fetchExtractionResult(documentID: DocumentID) throws -> ExtractionResult {
        extractionCallCount += 1
        guard !extractionResults.isEmpty else { throw DocumentServiceError.extractionUnavailable }
        return try extractionResults.removeFirst().get()
    }
}

private actor TestProcessingMonitor: DocumentProcessingMonitoring {
    private let statuses: [DocumentProcessingStatus]
    private let pausesAfterFirst: Bool
    private var continuation: CheckedContinuation<Void, Never>?

    init(statuses: [DocumentProcessingStatus], pausesAfterFirst: Bool = false) {
        self.statuses = statuses
        self.pausesAfterFirst = pausesAfterFirst
    }

    func waitForTerminalStatus(
        documentID: DocumentID,
        onStatusChange: @Sendable (DocumentProcessingStatus) async -> Void
    ) async throws -> DocumentProcessingStatus {
        guard let terminal = statuses.last else { throw DocumentProcessingMonitorError.timedOut }
        for (index, status) in statuses.enumerated() {
            try Task.checkCancellation()
            await onStatusChange(status)
            if pausesAfterFirst && index == 0 { await withCheckedContinuation { continuation = $0 } }
        }
        return terminal
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
    for _ in 0..<1_000 {
        if condition() { return }
        await Task.yield()
    }
    throw DocumentsViewModelTestError.timedOut
}

private enum DocumentsViewModelTestError: Error { case timedOut }

@MainActor
private func isUploading(_ state: DocumentsViewState) -> Bool {
    if case .uploading = state { return true }
    return false
}

@MainActor
private func isProcessing(_ state: DocumentsViewState, status: DocumentProcessingStatus) -> Bool {
    if case .processing(_, _, let currentStatus) = state { return currentStatus == status }
    return false
}

@MainActor
private func isCompleted(_ state: DocumentsViewState) -> Bool {
    if case .completed = state { return true }
    return false
}

@MainActor
private func isFailed(_ state: DocumentsViewState, error: DocumentsFeatureError) -> Bool {
    if case .failed(_, let currentError, _) = state { return currentError == error }
    return false
}

nonisolated private func makeRemoteDocument(status: DocumentProcessingStatus) -> SchoolDocument {
    SchoolDocument(
        id: DocumentID(rawValue: "document-1"),
        originalFilename: "newsletter.pdf",
        uploadedAt: Date(timeIntervalSince1970: 0),
        source: .pdfUpload,
        scope: .unknown,
        processingStatus: status,
        context: DocumentContext()
    )
}

nonisolated private func makeExtractionResult() throws -> ExtractionResult {
    let evidence = try SourceEvidence(
        sourceDocumentID: DocumentID(rawValue: "document-1"),
        excerpt: "School closes at 12:30."
    )
    let candidate = try ExtractionCandidate(
        id: "candidate-1",
        type: .pickupChange,
        title: "Early pickup",
        details: nil,
        startsAt: nil,
        endsAt: nil,
        isAllDay: false,
        confidence: try ExtractionConfidence(score: 0.9),
        evidence: [evidence]
    )
    return ExtractionResult(
        documentID: DocumentID(rawValue: "document-1"),
        schemaVersion: "1",
        generatedAt: Date(timeIntervalSince1970: 0),
        origin: .newlyProcessed,
        candidates: [candidate]
    )
}
