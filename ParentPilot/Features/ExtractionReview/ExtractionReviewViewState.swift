struct ExtractionReviewSummary: Equatable, Sendable {
    let accepted: Int
    let rejected: Int
    let unresolved: Int
    let needsAttention: Int
}
