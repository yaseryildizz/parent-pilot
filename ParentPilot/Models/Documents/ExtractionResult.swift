import Foundation

nonisolated struct ExtractionResult: Equatable, Sendable {
    let documentID: DocumentID
    let schemaVersion: String
    let generatedAt: Date
    let origin: ExtractionOrigin
    let candidates: [ExtractionCandidate]
}
