nonisolated struct SourceEvidenceDTO: Decodable, Sendable {
    let sourceDocumentID: String
    let excerpt: String
    let pageNumber: Int?
    let characterStart: Int?
    let characterEnd: Int?
}
