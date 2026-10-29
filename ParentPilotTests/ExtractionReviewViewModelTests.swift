import Foundation
import Testing

@testable import ParentPilot

@MainActor
struct ExtractionReviewViewModelTests {
    @Test
    func appliesDefaultPolicy() throws {
        let safe = try candidate(id: "safe", type: .reminder, score: 0.9)
        let low = try candidate(id: "low", type: .general, score: 0.4)
        let pickup = try candidate(id: "pickup", type: .pickupChange, score: 0.99)
        let model = ExtractionReviewViewModel(extractionResult: result([safe, low, pickup]))
        #expect(model.candidates.map(\.decision) == [.accepted, .undecided, .undecided])
        #expect(model.summary.accepted == 1)
        #expect(model.summary.unresolved == 2)
        #expect(model.summary.needsAttention == 1)
    }

    @Test
    func candidateActionsAndSafeBulkAcceptance() throws {
        let safe = try candidate(id: "safe", type: .activity, score: 0.2)
        let payment = try candidate(id: "payment", type: .payment, score: 1)
        let model = ExtractionReviewViewModel(extractionResult: result([safe, payment]))
        model.acceptSafeItems()
        #expect(model.candidates[0].decision == .accepted)
        #expect(model.candidates[1].decision == .undecided)
        model.decide(.rejected, candidateID: "payment")
        model.reset(candidateID: "payment")
        #expect(model.candidates[1].decision == .undecided)
    }

    @Test
    func unresolvedItemsBlockConfirmationThenResultIsRetained() throws {
        let item = try candidate(id: "event", type: .event, score: 0.95)
        let model = ExtractionReviewViewModel(extractionResult: result([item]))
        #expect(!model.canConfirm)
        #expect(model.confirmReview() == nil)
        model.decide(.accepted, candidateID: "event")
        let confirmed = try #require(model.confirmReview())
        #expect(confirmed.accepted.map(\.id) == ["event"])
        #expect(model.confirmedResult?.documentID == DocumentID(rawValue: "doc"))
    }

    @Test
    func sourceEvidenceIsPreservedAndExpandable() throws {
        let item = try candidate(id: "one", type: .task, score: 0.9)
        let model = ExtractionReviewViewModel(extractionResult: result([item]))
        #expect(model.candidates[0].candidate.evidence[0].excerpt == "Supporting source")
        model.toggleEvidence(candidateID: "one")
        #expect(model.candidates[0].isEvidenceExpanded)
    }

    @Test
    func zeroCandidateResultIsSafeButCannotConfirm() {
        let model = ExtractionReviewViewModel(extractionResult: result([]))
        #expect(model.candidates.isEmpty)
        #expect(!model.canConfirm)
    }

    private func candidate(id: String, type: ExtractionCandidateType, score: Double) throws
        -> ExtractionCandidate
    {
        try ExtractionCandidate(
            id: id,
            type: type,
            title: "Title",
            details: nil,
            startsAt: nil,
            endsAt: nil,
            isAllDay: false,
            confidence: ExtractionConfidence(score: score),
            evidence: [
                SourceEvidence(sourceDocumentID: DocumentID(rawValue: "doc"), excerpt: "Supporting source")
            ]
        )
    }

    private func result(_ candidates: [ExtractionCandidate]) -> ExtractionResult {
        ExtractionResult(
            documentID: DocumentID(rawValue: "doc"),
            schemaVersion: "1",
            generatedAt: .distantPast,
            origin: .newlyProcessed,
            candidates: candidates
        )
    }
}
