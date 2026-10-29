nonisolated struct ExtractionCandidateDTO: Decodable, Sendable {
    let id: String
    let type: String
    let title: String
    let details: String?
    let startsAt: String?
    let endsAt: String?
    let isAllDay: Bool
    let confidence: Double
    let evidence: [SourceEvidenceDTO]
    let isConflict: Bool?
    let isScheduleOverride: Bool?
    let temporal: ExtractedTemporalInfoDTO?
}
