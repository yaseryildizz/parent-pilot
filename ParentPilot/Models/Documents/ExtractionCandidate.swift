import Foundation

nonisolated struct ExtractionCandidate: Equatable, Sendable {
    let id: String
    let type: ExtractionCandidateType
    let title: String
    let details: String?
    let startsAt: Date?
    let endsAt: Date?
    let isAllDay: Bool
    let confidence: ExtractionConfidence
    let evidence: [SourceEvidence]
    let isConflict: Bool
    let isScheduleOverride: Bool
    let temporal: ExtractedTemporalInfo?

    init(
        id: String,
        type: ExtractionCandidateType,
        title: String,
        details: String?,
        startsAt: Date?,
        endsAt: Date?,
        isAllDay: Bool,
        confidence: ExtractionConfidence,
        evidence: [SourceEvidence],
        isConflict: Bool = false,
        isScheduleOverride: Bool = false,
        temporal: ExtractedTemporalInfo? = nil
    ) throws {
        guard !id.isEmpty, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentModelError.invalidCandidate
        }
        guard !evidence.isEmpty else { throw DocumentModelError.missingEvidence }
        if let startsAt, let endsAt {
            guard startsAt <= endsAt else { throw DocumentModelError.invalidCandidate }
        }
        self.id = id
        self.type = type
        self.title = title
        self.details = details
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.isAllDay = isAllDay
        self.confidence = confidence
        self.evidence = evidence
        self.isConflict = isConflict
        self.isScheduleOverride = isScheduleOverride
        self.temporal = temporal
    }
}
