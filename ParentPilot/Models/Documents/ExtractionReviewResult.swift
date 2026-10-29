nonisolated struct ExtractionReviewResult: Sendable {
    let documentID: DocumentID
    let accepted: [ExtractionCandidate]
    let rejected: [ExtractionCandidate]
}
