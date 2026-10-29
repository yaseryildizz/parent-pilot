import Foundation
import Observation

@MainActor
@Observable
final class ExtractionReviewViewModel: Identifiable {
    private let policy: ExtractionReviewPolicy
    private let extractionResult: ExtractionResult

    let id = UUID()
    private(set) var candidates: [ReviewableExtractionCandidate]
    private(set) var confirmedResult: ExtractionReviewResult?

    init(
        extractionResult: ExtractionResult,
        policy: ExtractionReviewPolicy = .init()
    ) {
        self.extractionResult = extractionResult
        self.policy = policy
        candidates = extractionResult.candidates.map {
            .init(candidate: $0, decision: policy.defaultDecision(for: $0))
        }
    }

    var summary: ExtractionReviewSummary {
        .init(
            accepted: count(.accepted),
            rejected: count(.rejected),
            unresolved: count(.undecided),
            needsAttention:
                candidates.filter { policy.requiresExplicitReview($0.candidate) && $0.decision == .undecided }
                .count
        )
    }

    var canConfirm: Bool { !candidates.isEmpty && summary.unresolved == 0 }

    func decide(_ decision: ExtractionReviewDecision, candidateID: String) {
        update(candidateID) { $0.decision = decision }
    }

    func reset(candidateID: String) { decide(.undecided, candidateID: candidateID) }

    func toggleEvidence(candidateID: String) { update(candidateID) { $0.isEvidenceExpanded.toggle() } }

    func acceptSafeItems() {
        for index in candidates.indices where policy.isSafeForBulkAcceptance(candidates[index].candidate) {
            candidates[index].decision = .accepted
        }
    }

    func rejectAll() { for index in candidates.indices { candidates[index].decision = .rejected } }

    @discardableResult
    func confirmReview() -> ExtractionReviewResult? {
        guard canConfirm else { return nil }
        let result = ExtractionReviewResult(
            documentID: extractionResult.documentID,
            accepted: candidates(with: .accepted),
            rejected: candidates(with: .rejected)
        )
        confirmedResult = result
        return result
    }

    func requiresAttention(_ item: ReviewableExtractionCandidate) -> Bool {
        policy.requiresExplicitReview(item.candidate)
            || item.candidate.confidence.score < policy.proposedHighConfidenceThreshold
    }
    private func count(_ decision: ExtractionReviewDecision) -> Int {
        candidates.filter { $0.decision == decision }.count
    }
    private func candidates(with decision: ExtractionReviewDecision) -> [ExtractionCandidate] {
        candidates.filter { $0.decision == decision }.map(\.candidate)
    }

    private func update(_ candidateID: String, change: (inout ReviewableExtractionCandidate) -> Void) {
        guard let index = candidates.firstIndex(where: { $0.id == candidateID }) else { return }
        change(&candidates[index])
    }
}
