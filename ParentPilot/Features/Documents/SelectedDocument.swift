import Foundation

nonisolated struct SelectedDocument: Identifiable, Equatable, Sendable {
    let id: UUID
    let temporaryURL: URL
    let displayFilename: String
    let fileSize: Int
    let mimeType: String
}
