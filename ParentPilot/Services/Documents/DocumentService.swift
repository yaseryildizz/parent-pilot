import Foundation

nonisolated protocol DocumentService: Sendable {
    func uploadDocument(at fileURL: URL, metadata: DocumentUploadMetadata) async throws -> SchoolDocument

    func fetchProcessingStatus(documentID: DocumentID) async throws -> DocumentProcessingStatus

    func fetchExtractionResult(documentID: DocumentID) async throws -> ExtractionResult
}
