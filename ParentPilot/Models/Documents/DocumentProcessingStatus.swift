nonisolated enum DocumentProcessingStatus: String, Codable, Sendable {
    case uploaded
    case queued
    case processing
    case completed
    case failed
}
