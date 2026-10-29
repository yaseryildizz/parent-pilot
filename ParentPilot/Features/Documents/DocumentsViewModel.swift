import Foundation
import Observation

@MainActor
@Observable
final class DocumentsViewModel {
    private enum Phase {
        case upload
        case processing
        case extraction
    }

    private let documentService: any DocumentService
    private let documentValidator: DocumentValidator
    private let documentImporter: any DocumentImporting
    private let processingMonitor: any DocumentProcessingMonitoring

    private(set) var state: DocumentsViewState = .idle

    private var operationTask: Task<Void, Never>?
    private var operationID = UUID()

    init(
        documentService: any DocumentService,
        documentValidator: DocumentValidator,
        documentImporter: any DocumentImporting = TemporaryDocumentImporter(),
        processingMonitor: any DocumentProcessingMonitoring
    ) {
        self.documentService = documentService
        self.documentValidator = documentValidator
        self.documentImporter = documentImporter
        self.processingMonitor = processingMonitor
    }

    func selectDocument(at sourceURL: URL) {
        let previousDocument = state.selectedDocument
        let operationID = beginOperation()
        state = .idle

        operationTask = Task { [weak self] in
            guard let self else { return }
            if let previousDocument { await documentImporter.removeTemporaryDocument(previousDocument) }

            do {
                let document = try await documentImporter.importPDF(
                    from: sourceURL,
                    validator: documentValidator
                )
                guard isCurrent(operationID) else {
                    await documentImporter.removeTemporaryDocument(document)
                    return
                }
                state = .selected(document)
            } catch is CancellationError { return } catch {
                guard isCurrent(operationID) else { return }
                state = .failed(nil, featureError(from: error), .chooseAnother)
            }
            finishOperation(operationID)
        }
    }

    func fileSelectionFailed(_ error: Error) {
        if error is CancellationError || (error as? CocoaError)?.code == .userCancelled { return }
        state = .failed(state.selectedDocument, .inaccessibleFile, .chooseAnother)
    }

    func analyzeSelectedDocument() {
        guard let document = uploadableDocument else { return }
        let operationID = beginOperation()
        state = .uploading(document)

        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let remoteDocument = try await documentService.uploadDocument(
                    at: document.temporaryURL,
                    metadata: DocumentUploadMetadata(scope: .unknown)
                )
                guard isCurrent(operationID) else { return }
                await continueProcessing(
                    selectedDocument: document,
                    remoteDocument: remoteDocument,
                    operationID: operationID
                )
            } catch is CancellationError { return } catch {
                fail(
                    operationID: operationID,
                    document: document,
                    error: featureError(from: error, phase: .upload),
                    retry: .upload
                )
            }
            finishOperation(operationID)
        }
    }

    func retryProcessing() {
        guard case .failed(let document, _, let retryAction) = state else { return }
        switch retryAction {
        case .chooseAnother: break
        case .upload: analyzeSelectedDocument()
        case .processing(let remoteDocument):
            guard let document else { return }
            monitorProcessing(document: document, remoteDocument: remoteDocument)
        case .extraction(let remoteDocument):
            guard let document else { return }
            fetchExtraction(document: document, remoteDocument: remoteDocument)
        }
    }

    func cancelProcessing() {
        operationTask?.cancel()
        operationTask = nil
        operationID = UUID()

        switch state {
        case .uploading(let document): state = .selected(document)
        case .processing(let document, let remoteDocument, let status):
            let retry: DocumentsRetryAction =
                status == .completed ? .extraction(remoteDocument) : .processing(remoteDocument)
            state = .failed(document, .cancelled, retry)
        default: break
        }
    }

    func reset() async {
        let document = state.selectedDocument
        cancelProcessing()
        state = .idle
        if let document { await documentImporter.removeTemporaryDocument(document) }
    }

    private var uploadableDocument: SelectedDocument? {
        switch state {
        case .selected(let document): document
        case .failed(let document?, _, .upload): document
        default: nil
        }
    }

    private func continueProcessing(
        selectedDocument: SelectedDocument,
        remoteDocument: SchoolDocument,
        operationID: UUID
    ) async {
        switch remoteDocument.processingStatus {
        case .completed:
            state = .processing(selectedDocument, remoteDocument, .completed)
            await fetchExtraction(
                document: selectedDocument,
                remoteDocument: remoteDocument,
                operationID: operationID
            )
        case .failed:
            fail(
                operationID: operationID,
                document: selectedDocument,
                error: .processingFailed,
                retry: .processing(remoteDocument)
            )
        case .uploaded, .queued, .processing:
            state = .processing(selectedDocument, remoteDocument, remoteDocument.processingStatus)
            await monitor(
                document: selectedDocument,
                remoteDocument: remoteDocument,
                operationID: operationID
            )
        }
    }

    private func monitorProcessing(document: SelectedDocument, remoteDocument: SchoolDocument) {
        let operationID = beginOperation()
        state = .processing(document, remoteDocument, remoteDocument.processingStatus)
        operationTask = Task { [weak self] in
            guard let self else { return }
            await monitor(document: document, remoteDocument: remoteDocument, operationID: operationID)
            finishOperation(operationID)
        }
    }

    private func monitor(document: SelectedDocument, remoteDocument: SchoolDocument, operationID: UUID) async
    {
        do {
            let terminalStatus = try await processingMonitor.waitForTerminalStatus(
                documentID: remoteDocument.id
            ) { [weak self] status in
                await self?
                    .updateProcessingStatus(
                        status,
                        document: document,
                        remoteDocument: remoteDocument,
                        operationID: operationID
                    )
            }
            guard isCurrent(operationID) else { return }
            if terminalStatus == .completed {
                await fetchExtraction(
                    document: document,
                    remoteDocument: remoteDocument,
                    operationID: operationID
                )
            } else {
                fail(
                    operationID: operationID,
                    document: document,
                    error: .processingFailed,
                    retry: .processing(remoteDocument)
                )
            }
        } catch is CancellationError { return } catch is DocumentProcessingMonitorError {
            fail(
                operationID: operationID,
                document: document,
                error: .processingTimedOut,
                retry: .processing(remoteDocument)
            )
        } catch {
            fail(
                operationID: operationID,
                document: document,
                error: featureError(from: error, phase: .processing),
                retry: .processing(remoteDocument)
            )
        }
    }

    private func fetchExtraction(document: SelectedDocument, remoteDocument: SchoolDocument) {
        let operationID = beginOperation()
        state = .processing(document, remoteDocument, .completed)
        operationTask = Task { [weak self] in
            guard let self else { return }
            await fetchExtraction(
                document: document,
                remoteDocument: remoteDocument,
                operationID: operationID
            )
            finishOperation(operationID)
        }
    }

    private func fetchExtraction(
        document: SelectedDocument,
        remoteDocument: SchoolDocument,
        operationID: UUID
    ) async {
        do {
            let result = try await documentService.fetchExtractionResult(documentID: remoteDocument.id)
            guard isCurrent(operationID) else { return }
            state = .completed(document, remoteDocument, result)
        } catch is CancellationError { return } catch {
            fail(
                operationID: operationID,
                document: document,
                error: featureError(from: error, phase: .extraction),
                retry: .extraction(remoteDocument)
            )
        }
    }

    private func updateProcessingStatus(
        _ status: DocumentProcessingStatus,
        document: SelectedDocument,
        remoteDocument: SchoolDocument,
        operationID: UUID
    ) {
        guard isCurrent(operationID) else { return }
        state = .processing(document, remoteDocument, status)
    }

    private func beginOperation() -> UUID {
        operationTask?.cancel()
        let id = UUID()
        operationID = id
        operationTask = nil
        return id
    }

    private func isCurrent(_ id: UUID) -> Bool { operationID == id && !Task.isCancelled }

    private func finishOperation(_ id: UUID) {
        guard operationID == id else { return }
        operationTask = nil
    }

    private func fail(
        operationID: UUID,
        document: SelectedDocument?,
        error: DocumentsFeatureError,
        retry: DocumentsRetryAction
    ) {
        guard isCurrent(operationID) else { return }
        state = .failed(document, error, retry)
    }

    private func featureError(from error: Error, phase: Phase? = nil) -> DocumentsFeatureError {
        if let error = error as? DocumentServiceError {
            switch error {
            case .unsupportedDocument: return .unsupportedDocument
            case .fileAccessFailed: return .inaccessibleFile
            case .fileTooLarge: return .fileTooLarge
            case .extractionUnavailable: return .extractionUnavailable
            case .processingFailed: return .processingFailed
            case .uploadFailed, .requestFailed, .invalidServerResponse: break
            }
        }

        switch phase {
        case .upload: return .uploadFailed
        case .processing: return .processingFailed
        case .extraction: return .extractionUnavailable
        case nil: return .inaccessibleFile
        }
    }
}

#if DEBUG
    extension DocumentsViewModel { func setPreviewState(_ state: DocumentsViewState) { self.state = state } }
#endif
