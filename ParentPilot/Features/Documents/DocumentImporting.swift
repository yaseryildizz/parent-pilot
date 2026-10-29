import Foundation

nonisolated protocol DocumentImporting: Sendable {
    func importPDF(from sourceURL: URL, validator: DocumentValidator) async throws -> SelectedDocument

    func removeTemporaryDocument(_ document: SelectedDocument) async
}

actor TemporaryDocumentImporter: DocumentImporting {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    func importPDF(from sourceURL: URL, validator: DocumentValidator) throws -> SelectedDocument {
        let accessedSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessedSecurityScope { sourceURL.stopAccessingSecurityScopedResource() } }

        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ParentPilotImports", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let filename = sourceURL.lastPathComponent.isEmpty ? "document.pdf" : sourceURL.lastPathComponent
        let destinationURL = directory.appendingPathComponent(filename)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            let validated = try validator.validate(fileURL: destinationURL)
            return SelectedDocument(
                id: UUID(),
                temporaryURL: destinationURL,
                displayFilename: validated.filename,
                fileSize: validated.contents.count,
                mimeType: validated.mimeType
            )
        } catch let error as DocumentServiceError {
            try? fileManager.removeItem(at: directory)
            throw error
        } catch {
            try? fileManager.removeItem(at: directory)
            throw DocumentServiceError.fileAccessFailed
        }
    }

    func removeTemporaryDocument(_ document: SelectedDocument) {
        let directory = document.temporaryURL.deletingLastPathComponent()
        try? fileManager.removeItem(at: directory)
    }
}
