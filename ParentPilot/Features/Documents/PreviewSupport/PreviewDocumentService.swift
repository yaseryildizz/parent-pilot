#if DEBUG
    import Foundation

    nonisolated struct PreviewDocumentService: DocumentService {
        func uploadDocument(at fileURL: URL, metadata: DocumentUploadMetadata) async throws -> SchoolDocument
        { throw DocumentServiceError.uploadFailed }

        func fetchProcessingStatus(documentID: DocumentID) async throws -> DocumentProcessingStatus {
            throw DocumentServiceError.requestFailed
        }

        func fetchExtractionResult(documentID: DocumentID) async throws -> ExtractionResult {
            throw DocumentServiceError.extractionUnavailable
        }
    }
#endif
