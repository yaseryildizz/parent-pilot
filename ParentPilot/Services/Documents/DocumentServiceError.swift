nonisolated enum DocumentServiceError: Error, Equatable, Sendable {
    case unsupportedDocument
    case fileAccessFailed
    case fileTooLarge(maximumBytes: Int64?)
    case uploadFailed
    case requestFailed
    case processingFailed
    case extractionUnavailable
    case invalidServerResponse
}
