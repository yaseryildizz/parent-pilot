nonisolated enum DocumentModelError: Error, Equatable, Sendable {
    case invalidConfidence
    case invalidEvidence
    case missingEvidence
    case invalidCandidate
}
