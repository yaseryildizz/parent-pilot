nonisolated struct CalendarProvenance: Equatable, Sendable {
    let extractionCandidateID: String
    let evidence: [SourceEvidence]
}
