nonisolated struct ExtractionResultDTO: Decodable, Sendable {
    let documentID: String
    let schemaVersion: String
    let generatedAt: String
    let origin: String
    let candidates: [ExtractionCandidateDTO]
}
