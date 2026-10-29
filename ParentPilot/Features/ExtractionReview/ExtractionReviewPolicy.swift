nonisolated struct ExtractionReviewPolicy: Sendable {
    /// Proposed MVP threshold; validate through AI evaluation before treating as permanent.
    let proposedHighConfidenceThreshold: Double

    init(proposedHighConfidenceThreshold: Double = 0.85) {
        self.proposedHighConfidenceThreshold = proposedHighConfidenceThreshold
    }

    func requiresExplicitReview(_ candidate: ExtractionCandidate) -> Bool {
        candidate.isConflict || candidate.isScheduleOverride
            || [.pickupChange, .payment, .holiday, .event].contains(candidate.type)
    }

    func defaultDecision(for candidate: ExtractionCandidate) -> ExtractionReviewDecision {
        guard !requiresExplicitReview(candidate), !candidate.evidence.isEmpty,
            candidate.confidence.score >= proposedHighConfidenceThreshold
        else { return .undecided }
        return .accepted
    }

    func isSafeForBulkAcceptance(_ candidate: ExtractionCandidate) -> Bool {
        !requiresExplicitReview(candidate) && !candidate.evidence.isEmpty
    }
}
