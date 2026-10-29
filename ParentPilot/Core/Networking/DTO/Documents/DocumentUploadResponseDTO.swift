nonisolated struct DocumentUploadResponseDTO: Decodable, Sendable {
    let id: String
    let originalFilename: String
    let uploadedAt: String
    let source: String
    let scope: String
    let processingStatus: String
    let schoolID: String?
    let childID: String?
    let classID: String?
}
