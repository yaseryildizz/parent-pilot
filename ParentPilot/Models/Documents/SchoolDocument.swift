import Foundation

nonisolated struct SchoolDocument: Equatable, Sendable {
    let id: DocumentID
    let originalFilename: String
    let uploadedAt: Date
    let source: DocumentSource
    let scope: DocumentScope
    let processingStatus: DocumentProcessingStatus
    let context: DocumentContext
}
