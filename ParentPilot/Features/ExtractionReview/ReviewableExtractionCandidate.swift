import Foundation

nonisolated enum ExtractionReviewDecision: Equatable, Sendable { case undecided, accepted, rejected }

nonisolated struct ReviewableExtractionCandidate: Identifiable, Sendable {
    let candidate: ExtractionCandidate
    var decision: ExtractionReviewDecision
    var isEvidenceExpanded = false
    var id: String { candidate.id }
}
