import Foundation

nonisolated struct DocumentPollingPolicy: Sendable {
    let interval: Duration
    let maximumAttempts: Int

    static let proposedMVP = DocumentPollingPolicy(interval: .seconds(2), maximumAttempts: 30)
}

nonisolated enum DocumentProcessingMonitorError: Error, Equatable, Sendable { case timedOut }

nonisolated protocol DocumentProcessingSleeping: Sendable { func sleep(for duration: Duration) async throws }

nonisolated struct ContinuousClockDocumentSleeper: DocumentProcessingSleeping {
    func sleep(for duration: Duration) async throws { try await ContinuousClock().sleep(for: duration) }
}

nonisolated protocol DocumentProcessingMonitoring: Sendable {
    func waitForTerminalStatus(
        documentID: DocumentID,
        onStatusChange: @Sendable (DocumentProcessingStatus) async -> Void
    ) async throws -> DocumentProcessingStatus
}

nonisolated struct DocumentProcessingMonitor: DocumentProcessingMonitoring {
    private let documentService: any DocumentService
    private let policy: DocumentPollingPolicy
    private let sleeper: any DocumentProcessingSleeping

    init(
        documentService: any DocumentService,
        policy: DocumentPollingPolicy = .proposedMVP,
        sleeper: any DocumentProcessingSleeping = ContinuousClockDocumentSleeper()
    ) {
        self.documentService = documentService
        self.policy = policy
        self.sleeper = sleeper
    }

    func waitForTerminalStatus(
        documentID: DocumentID,
        onStatusChange: @Sendable (DocumentProcessingStatus) async -> Void
    ) async throws -> DocumentProcessingStatus {
        guard policy.maximumAttempts > 0 else { throw DocumentProcessingMonitorError.timedOut }

        for attempt in 1...policy.maximumAttempts {
            try Task.checkCancellation()
            let status = try await documentService.fetchProcessingStatus(documentID: documentID)
            await onStatusChange(status)

            switch status {
            case .completed, .failed: return status
            case .uploaded, .queued, .processing:
                if attempt < policy.maximumAttempts { try await sleeper.sleep(for: policy.interval) }
            }
        }

        throw DocumentProcessingMonitorError.timedOut
    }
}
